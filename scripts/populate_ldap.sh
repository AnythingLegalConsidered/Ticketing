#!/bin/bash
# Script de peuplement automatique du LDAP avec des utilisateurs et groupes de test
# Génère dynamiquement un fichier LDIF et l'importe dans OpenLDAP
# Facilement configurable via les variables GROUPS et USERS

# Variables (modifiez ici pour ajouter/supprimer)
DOMAIN="projet.lan"
BASE_DN="dc=projet,dc=lan"
LDAP_ADMIN_DN="cn=admin,$BASE_DN"
LDAP_PASSWORD="${LDAP_ROOT_PASSWORD:-YourStrongLdapPassword}"  # Utilise la variable env ou le mot de passe du .env
echo "Using password: $LDAP_PASSWORD"

# Groupes à créer
LDAP_GROUPS=("N1" "N2" "N3" "Users")

# Utilisateurs par groupe (format: uid:prenom:nom:email:uidNumber)
# Modifiez cette liste pour ajouter/supprimer des utilisateurs
declare -A USERS
USERS[N3]="bob.ladmin:Bob:Ladmin:bob.ladmin@projet.lan:10001"
USERS[N2]="robert.lemodo:Robert:Lemodo:robert.lemodo@projet.lan:10002"
USERS[N1]="chris.letech:Chris:Letech:chris.letech@projet.lan:10003"
USERS[Users]="jean.user:Jean:User:jean.user@projet.lan:10004"

# Hash du mot de passe "password" (généré avec slappasswd -s password)
PASSWORD_HASH="{SSHA}uWB7hQ3htBe4AGfQpOPcD7e1GeWwP5dt"

# Générer le LDIF
LDIF_FILE="/tmp/populate_ldap.ldif"
cat > "$LDIF_FILE" << EOF
# LDIF généré automatiquement pour peupler LDAP

# Structure de base (OUs)
dn: ou=users,$BASE_DN
objectClass: organizationalUnit
ou: users

dn: ou=groups,$BASE_DN
objectClass: organizationalUnit
ou: groups

# Groupes
EOF

# Ajouter les groupes
for group in "${LDAP_GROUPS[@]}"; do
    cat >> "$LDIF_FILE" << EOF
dn: cn=$group,ou=groups,$BASE_DN
objectClass: groupOfNames
cn: $group
member: cn=admin,$BASE_DN
EOF

    # Ajouter les membres du groupe s'ils sont définis dans USERS
    if [ -n "${USERS[$group]}" ]; then
        for user_info in ${USERS[$group]}; do
            IFS=':' read -r uid prenom nom email uidNumber <<< "$user_info"
            echo "member: uid=$uid,ou=users,$BASE_DN" >> "$LDIF_FILE"
        done
    fi

    echo "" >> "$LDIF_FILE"
done

# Ajouter les utilisateurs
cat >> "$LDIF_FILE" << EOF
# Utilisateurs
EOF

for group in "${!USERS[@]}"; do
    for user_info in ${USERS[$group]}; do
        IFS=':' read -r uid prenom nom email uidNumber <<< "$user_info"
        cat >> "$LDIF_FILE" << EOF
dn: uid=$uid,ou=users,$BASE_DN
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: top
cn: $prenom $nom
sn: $nom
givenName: $prenom
uid: $uid
uidNumber: $uidNumber
gidNumber: 10000
homeDirectory: /home/$uid
mail: $email
userPassword: $PASSWORD_HASH

EOF
    done
done

# Importer le LDIF
echo "Importation du LDIF dans LDAP..."
ldapmodify -x -H ldap://openldap -D "$LDAP_ADMIN_DN" -w "$LDAP_PASSWORD" -a -c -f "$LDIF_FILE" 2>&1 | grep -v "Already exists"

# Vérifier si l'importation a réussi (ignorer les erreurs "Already exists")
if [ $? -eq 0 ] || [ $? -eq 68 ]; then
    echo "LDAP peuplé avec succès !"
    echo "Utilisateurs créés :"
    for group in "${!USERS[@]}"; do
        echo "  Groupe $group :"
        for user_info in ${USERS[$group]}; do
            IFS=':' read -r uid prenom nom email uidNumber <<< "$user_info"
            echo "    - $uid ($prenom $nom) / password (UID: $uidNumber)"
        done
    done
else
    echo "Erreur lors de l'importation. Vérifiez les logs."
    exit 1
fi
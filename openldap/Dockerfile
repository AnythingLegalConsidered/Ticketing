FROM osixia/openldap:1.5.0

# Add our custom bootstrap LDIF into the image so the container can modify/remove files
COPY 05-base-structure.ldif /container/service/slapd/assets/config/bootstrap/ldif/custom/05-base-structure.ldif

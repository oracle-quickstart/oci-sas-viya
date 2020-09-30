# Configure PostgreSQL
By default, Viya 4 will not add a PostgreSQL instance to the kubernetes
deployment. This is because in Viya 4 you have two options for your
PostgreSQL server: an internal instance provided by SAS or an external
PostgreSQL that you would like SAS to utilize. So, before deploying we
need you to select which of these options you would like to use for your
SAS deployment.

This is done by applying overlays to your deployment, which SAS has provided
for you. We just need some additional information from you to apply them.

## Internal PostgreSQL
If you wish for SAS to create a PostgreSQL instance for you and use that,
apply the `interal-postgres` overlays. To do so, refer to the
`$deploy/sas-bases/overlays/internal-postgres` directory. There you will find
a README file describing the actions you need to take.

## External PostgreSQL
If you wish for SAS to make use of an external PostgreSQL provided and managed
by you, apply the `external-postgres` overlay. To do so, refer to the
`$deploy/sas-bases/overlays/external-postgres` directory. There you will find
a README file describing the actions you need to take.
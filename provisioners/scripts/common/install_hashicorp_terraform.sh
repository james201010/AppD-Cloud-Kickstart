#!/bin/sh -eux
#---------------------------------------------------------------------------------------------------
# Install Terraform Infrastructure as Code Tool by HashiCorp.
#
# Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently.
# Terraform can manage existing and popular service providers as well as custom in-house solutions.
#
# Configuration files describe to Terraform the components needed to run a single application or
# your entire datacenter. Terraform generates an execution plan describing what it will do to
# reach the desired state, and then executes it to build the described infrastructure. As the
# configuration changes, Terraform is able to determine what changed and create incremental
# execution plans which can be applied.
#
# The infrastructure Terraform can manage includes low-level components such as compute instances,
# storage, and networking, as well as high-level components such as DNS entries, SaaS features,
# etc.
#
# The key features of Terraform are:
# - Infrastructure as Code
# - Execution Plans
# - Resource Graph
# - Change Automation
#
# For more details, please visit:
#   https://terraform.io/
#
# NOTE: Script should be run with 'root' privilege.
#---------------------------------------------------------------------------------------------------

# install hashicorp terraform. ---------------------------------------------------------------------
terraform_release="1.0.9"
terraform_binary="terraform_${terraform_release}_linux_amd64.zip"
terraform_sha256="f06ac64c6a14ed6a923d255788e4a5daefa2b50e35f32d7a3b5a2f9a5a91e255"

# create local bin directory (if needed).
mkdir -p /usr/local/bin
cd /usr/local/bin

# download terraform binary from hashicorp.com.
rm -f ${terraform_binary}
wget --no-verbose https://releases.hashicorp.com/terraform/${terraform_release}/${terraform_binary}

# verify the downloaded binary.
echo "${terraform_sha256} ${terraform_binary}" | sha256sum --check
# terraform_${terraform_release}_linux_amd64.zip: OK

# extract terraform binary.
rm -f terraform
unzip ${terraform_binary}
chmod 755 terraform
rm -f ${terraform_binary}

# verify installation. -----------------------------------------------------------------------------
# set terraform environment variables.
PATH=/usr/local/bin:$PATH
export PATH

# verify terraform version.
terraform --version

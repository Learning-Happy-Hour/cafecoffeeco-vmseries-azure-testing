# Securing CafeCoffeeCo's Azure testing infrastructure with VM-Series firewalls

I have used Terraform to build CafeCoffeeCo's testing website, Panorama server and VM-Series firewalls. Each terraform script deploys a resource group with multiple resources, including VNET, VMs, NICs, NSGs and more. There will be three resource groups (App, Management and Transit).

**Notes:** 

1. This guide is written for bash shell

2. The Azure location is set to "Australia East". Set the location to your preferred location by changing the "location" variable value in __terraform.tfvars__ file.

## 1. CafeCoffeeCo Application Setup

Terraform script in the [ccc-azure-app](/ccc-azure-app/) folder deploys an Apache2 webserver on Ubuntu 22.04 LTS with the IP address of 10.112.1.4. The NSG assigned to the subnet allows access from any source IP address to TCP port 22 and 80.

### Deployment steps:

- Download the scripts:

    ```
    git clone https://github.com/Learning-Happy-Hour/cafecoffeeco-vmseries-azure-testing
- (Optional) authenticate to AzureRM, switch to the Subscription of your choice if necessary

- Initialize the Terraform module:

    ```
    cd cafecoffeeco-vmseries-azure-testing/ccc-azure-app
    ```
    ```
    terraform init
    ```
- (Optional) plan your infrastructure to see what will be actually deployed:
    
     ```
    terraform plan
    ```    
- Deploy the infrastructure (you will have to confirm it by typing in yes):

    ```
    terraform apply
    ```
- The deployment takes a few minutes. The output should be similar to the screenshot below:

  ![terraform output](/ccc-azure-app/ccc-app-screenshot.jpg)

## 2. CafeCoffeeCo Panorama (Management) Setup 

The Terraform script in [ccc-panorama](/ccc-panorama/) folder deploys a Panorama server (version 10.2.3) with one NIC. The NIC will have a private IP address of 10.255.0.4 and a dynamic public IP address. Once the panorama web interface is reachable, login to the server to import and load the baseline configuration. Follow the below deployment steps for more info.

### Deployment steps

- (optional) authenticate to AzureRM, switch to the Subscription of your choice if necessary

- Initialize the Terraform module:
    ```
    cd ~/cafecoffeeco-vmseries-azure-testing/ccc-panorama
    ```
    ```
    terraform init
    ```
- (optional) plan your infrastructure to see what will be actually deployed:
    
     ```
    terraform plan
    ```    
- Deploy the infrastructure (you will have to confirm it by typing in yes):

    ```
    terraform apply
    ```
- The deployment takes around 10 minutes. The output should be similar to the screenshot below:

    ![terraform output](/ccc-panorama/ccc-panorama-screenshot.jpg)


- Wait for a few minutes for Panorama to boot up.
- Use the public IP address in the output summary to connect to Panorama:

    https://\<panorama-public-ip\>

-  username: panadmin

- For password, run the below command:

    ```
    terraform output password
    ```
- Login to Panorama and enter the provisioned serial number as part of the Software NGFW Deployment profile.
- Login to panorama and retrieve the licenses. 
- Import and load the baseline config ([basline-config.xml](/ccc-panorama/baseline-config.xml)).
- Before committing the configuration, define a new Panorama administrator so you don't lock yourself out!
- Download and Install the Software Licensing Plugin. 
- Under the plugin, add a bootstrap definition and a license manager.
- Commit to panorama
- Take note of bootstrap parameters (especially auth-key) under the license manager


## 3. CafeCoffeeCo Common VM-series Firewall Setup

The Terraform script in [ccc-common-vmseries](/ccc-common-vmseries/) folder deploys two vm-series firewalls with four vCPUs and three interfaces, a public load-balancer and a private load-balancer. It configures vnet peering between transit vnet and the other two vnets. To ensure that the web server has inbound and outbound internet access, follow the below steps.


### Deployment steps

- Setup bootstrapping options in  **terraform.tfvars** file. 
    ```
    cd ~/cafecoffeeco-vmseries-azure-testing/ccc-common-vmseries
    ```
   
-  In the Panorama SW Firewall License plugin, copy the **auth-key** value from bootstrap parameters (the  **ACTION** column of the License Manager). 

- In **terraform.tfvars**, paste the value in **bootstrap_options** auth-key value for both fw-1 and fw-2:  

    
    ```
    nano terraform.tfvars
    ```
    The result should look like:

    
    > bootstrap_options = "type=dhcp-client;panorama-server=10.255.0.4;__**auth-key=\<auth-key-value\>**__;dgname=Azure Transit_DG;tplname=Azure Transit_TS;plugin-op-commands=panorama-licensing-mode-on;dhcp-accept-server-hostname=yes;dhcp-accept-server-domain=yes"
    
- Initialize the Terraform module:

    ```
    terraform init
    ```
- (optional) plan your infrastructure to see what will be actually deployed:
    
     ```
    terraform plan
    ```    
- Deploy the infrastructure (you will have to confirm it by typing in yes):

    ```
    terraform apply
    ```
- It will take up to 15 minutes to successfully build the resources. Once finished, the result should look like this:

    ![terraform output](/ccc-common-vmseries/ccc-vmseries-screenshot.jpg)


- While the resources are being deployed, define a route table in ccc-app-rg resource group. Create a UDR for destination  0.0.0.0/0 with the next hop of 10.110.0.21 (private LB's frontend IP address). Associate the route with app-subnet01.

    ![default route for the app](/ccc-common-vmseries/default-route-definition.jpg)

    ![route table association with the subnet](/ccc-common-vmseries/route-association.jpg)

- the effective route on app-nic should look like:
    ![effective routes on app-nic](/ccc-common-vmseries/effective%20routes.jpg)

- Get the frontend IP address of Public LB:
    ```
    terraform output lb_frontend_ips
    ```
- Go to panorama and set the IP address of the **public-lb-ip-address** address object to public LB's frontend IP address.
    ![address object](/ccc-common-vmseries/address%20object.jpg)

- commit and push the configuration.
- CafeCoffeeCo's website (http://\<public-lb-frontend\>) should be accessible after a successful firewall commit.

## 4. Useful Links

- [Terraform for Software NGFW](https://pan.dev/swfw/) 
- [Palo Alto Networks  Reference Architecture Guides](https://www.paloaltonetworks.com/resources/reference-architectures)
- [Terraform VM-Series Modules in Github](https://github.com/PaloAltoNetworks/terraform-azurerm-vmseries-modules)
- [Palo Alto Networks as Code with Terraform](https://pan.dev/terraform/)
- [VM-Series Tech Docs](https://docs.paloaltonetworks.com/vm-series)
- [Software NGFW Credit Estimator](https://www.paloaltonetworks.com/resources/tools/ngfw-credits-estimator)




New in Viya 2021.2.6: The connect workload class is not required, Connect Workload Class Changes
 
To deploy Viya 2021.2.6 and forward, use this new IAC version 5.0.0. The default is no connect node pool. If your current order has a requirement for the connect node pool you can use the connect node pool example file in examples/sample-input-connect.tfvars
 
To update from previous Viya to 2021.2.6: 
1.	Perform the update following SAS documentation 
2.	Successfully updated to 2021.2.6. Instances in Connect node pool can now be removed. 
3.	Use the examples/sample-input.tfvars or edit your customized variable definition file (tfvars) to remove "connect={}" in the "node_pools" section
4.	Run terraform apply using your edited tfvars

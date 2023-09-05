from diagrams import Cluster, Diagram
from diagrams.aws.compute import EKS, EC2, AutoScaling
from diagrams.aws.network import VPC, PrivateSubnet, PublicSubnet
from diagrams.aws.security import IAMRole

with Diagram("AWS Resources from Terraform", show=False):
    with Cluster("VPC: custom_vpc_mnka"):
        vpc = VPC("custom_vpc_mnka")
        
        role = IAMRole("IAM Role for Node Group")
        vpc >> role
        
        with Cluster("us-west-2a"):
            public_subnet_1 = PublicSubnet("public_subnet_1_mnka")
            private_subnet_1 = PrivateSubnet("private_subnet_1_mnka")
            
        with Cluster("us-west-2b"):
            public_subnet_2 = PublicSubnet("public_subnet_2_mnka")
            private_subnet_2 = PrivateSubnet("private_subnet_2_mnka")
            
        with Cluster("EKS Cluster across AZs"):
            eks = EKS("EKS Cluster")
            public_subnet_1 >> eks
            public_subnet_2 >> eks

            with Cluster("Node Group across AZs"):
                nodegroup = EKS("EKS Node Group")
                eks >> nodegroup
                
                role >> nodegroup

                with Cluster("AutoScaling in AZ1"):
                    autoscaling1 = AutoScaling("AutoScaling")
                    nodegroup >> autoscaling1
                    
                    ec2_1 = EC2("EC2 Instance 1")
                    autoscaling1 >> ec2_1
                    ec2_1 >> public_subnet_1

                with Cluster("AutoScaling in AZ2"):
                    autoscaling2 = AutoScaling("AutoScaling")
                    nodegroup >> autoscaling2

                    ec2_2 = EC2("EC2 Instance 2")
                    autoscaling2 >> ec2_2
                    ec2_2 >> public_subnet_2


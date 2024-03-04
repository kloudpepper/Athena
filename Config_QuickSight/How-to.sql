#yyyy-MM-dd'T'HH:mm:ss.SSSZ


#Crear la tabla
CREATE EXTERNAL TABLE aws_config_configuration_snapshot (
       fileversion STRING,
       configsnapshotid STRING,
       configurationitems ARRAY < STRUCT <
       configurationItemVersion : STRING,
       configurationItemCaptureTime : STRING,
       configurationStateId : BIGINT,
       awsAccountId : STRING,
       configurationItemStatus : STRING,
       resourceType : STRING,
       resourceId : STRING,
       resourceName : STRING,
       ARN : STRING,
       awsRegion : STRING,
       availabilityZone : STRING,
       configurationStateMd5Hash : STRING,
       configuration : STRING,
       supplementaryConfiguration : MAP < STRING, STRING >,
       tags: MAP < STRING, STRING >,
       resourceCreationTime : STRING > >
       )
       PARTITIONED BY ( accountid STRING, dt STRING , region STRING )
       ROW FORMAT SERDE
       'org.openx.data.jsonserde.JsonSerDe'
       WITH SERDEPROPERTIES (
              'case.insensitive'='false',
              'mapping.fileversion'='fileVersion',
              'mapping.configsnapshotid'='configSnapshotId',
              'mapping.configurationitems'='configurationItems',
              'mapping.configurationitemversion'='configurationItemVersion',
              'mapping.configurationitemcapturetime'='configurationItemCaptureTime',
              'mapping.configurationstateid'='configurationStateId',
              'mapping.awsaccountid'='awsAccountId',
              'mapping.configurationitemstatus'='configurationItemStatus',
              'mapping.resourcetype'='resourceType',
              'mapping.resourceid'='resourceId',
              'mapping.resourcename'='resourceName',
              'mapping.arn'='ARN',
              'mapping.awsregion'='awsRegion',
              'mapping.availabilityzone'='availabilityZone',
              'mapping.configurationstatemd5hash'='configurationStateMd5Hash',
              'mapping.supplementaryconfiguration'='supplementaryConfiguration',
              'mapping.configurationstateid'='configurationStateId'
              )LOCATION 's3://aws-controltower-logs-223293441139-us-east-1/o-l6qcpc3qam/AWSLogs/';



#######Extraer inventario########

#VPC
## Athena ##
SELECT configurationItem.configurationItemCaptureTime as CreationTime,
       configurationItem.resourceType as ResourceType,
       accountid as AccountID,
       configurationItem.tags['Environment'] as Environment,
       configurationItem.awsRegion as Region,
       configurationItem.resourceId as VpcID,
       configurationItem.tags['Name'] as VpcName,
       json_extract_scalar(configurationItem.configuration, '$.cidrBlock') as CidrBlock,
       json_extract_scalar(configurationItem.configuration, '$.dhcpOptionsId') as DhcpOptionsId
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
WHERE dt = 'latest'
AND configurationItem.resourceType = 'AWS::EC2::VPC'
AND (configurationItem.awsRegion = 'us-east-1' OR configurationItem.awsRegion = 'us-west-2')
AND NOT configurationItem.tags['Name'] = 'aws-controltower-VPC'
ORDER BY AccountID

## QuickSight ##
CREATE OR REPLACE VIEW Inventario_VPC AS
SELECT DISTINCT
"configurationItem"."configurationitemcapturetime" "CreationTime"
,"configurationItem"."resourceType" "ResourceType"
,"accountid" "AccountID"
,"configurationItem"."tags"['Environment'] "Environment"
,"configurationItem"."awsRegion" "Region"
,"configurationItem"."resourceId" "VpcID"
,"configurationItem"."tags"['Name'] "VpcName"
,"json_extract_scalar"("configurationItem"."configuration", '$.cidrBlock') "CidrBlock"
,"json_extract_scalar"("configurationItem"."configuration", '$.dhcpOptionsId') "DhcpOptionsId"
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST("configurationitems") t (configurationItem)
WHERE (("dt" = 'latest') AND ("configurationItem"."resourcetype" = 'AWS::EC2::VPC') AND ("configurationItem"."awsRegion" = 'us-east-1' OR "configurationItem"."awsRegion" = 'us-west-2') AND NOT ("configurationItem"."tags"['Name'] = 'aws-controltower-VPC'))
ORDER BY AccountID


#Subnets
## Athena ##
SELECT configurationItem.configurationItemCaptureTime as CreationTime,
       configurationItem.resourceType as ResourceType,
       accountid as AccountID,
       configurationItem.tags['Environment'] as Environment,
       configurationItem.awsRegion as Region,
       json_extract_scalar(configurationItem.configuration, '$.availabilityZone') as AvailabilityZone,
       json_extract_scalar(configurationItem.configuration, '$.availabilityZoneId') as AvailabilityZoneID,
       configurationItem.resourceId as SubnetID,
       configurationItem.tags['Name'] as SubnetName,
       json_extract_scalar(configurationItem.configuration, '$.vpcId') as VpcID,
       json_extract_scalar(configurationItem.configuration, '$.cidrBlock') as CidrBlock,
       json_extract_scalar(configurationItem.configuration, '$.availableIpAddressCount') as AvailableIpAddressCount,
       json_extract_scalar(configurationItem.configuration, '$.mapPublicIpOnLaunch') as MapPublicIpOnLaunch
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
WHERE dt = 'latest'
AND configurationItem.resourceType = 'AWS::EC2::Subnet'
AND (configurationItem.awsRegion = 'us-east-1' OR configurationItem.awsRegion = 'us-west-2')
AND NOT configurationItem.tags['Name'] = 'aws-controltower'
ORDER BY AccountID

## QuickSight ##
CREATE OR REPLACE VIEW Inventario_Subnets AS
SELECT DISTINCT
"configurationItem"."configurationitemcapturetime" "CreationTime"
,"configurationItem"."resourceType" "ResourceType"
,"accountid" "AccountID"
,"configurationItem"."tags"['Environment'] "Environment"
,"configurationItem"."awsRegion" "Region"
,"json_extract_scalar"("configurationItem"."configuration", '$.availabilityZone') "AvailabilityZone"
,"json_extract_scalar"("configurationItem"."configuration", '$.availabilityZoneId') "AvailabilityZoneID"
,"configurationItem"."resourceId" "SubnetID"
,"configurationItem"."tags"['Name'] "SubnetName"
,"json_extract_scalar"("configurationItem"."configuration", '$.vpcId') "VpcID"
,"json_extract_scalar"("configurationItem"."configuration", '$.cidrBlock') "CidrBlock"
,"json_extract_scalar"("configurationItem"."configuration", '$.availableIpAddressCount') "AvailableIpAddressCount"
,"json_extract_scalar"("configurationItem"."configuration", '$.mapPublicIpOnLaunch') "MapPublicIpOnLaunch"
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST("configurationitems") t (configurationItem)
WHERE (("dt" = 'latest') AND ("configurationItem"."resourcetype" = 'AWS::EC2::Subnet') AND ("configurationItem"."awsRegion" = 'us-east-1' OR "configurationItem"."awsRegion" = 'us-west-2') AND NOT ("configurationItem"."tags"['Name'] = 'aws-controltower'))
ORDER BY AccountID


#RouteTable
## Athena ##
SELECT configurationItem.configurationItemCaptureTime as CreationTime,
       configurationItem.resourceType as ResourceType,
       accountid as AccountID,
       configurationItem.tags['Environment'] as Environment,
       configurationItem.awsRegion as Region,
       configurationItem.resourceId as RouteTableID,
       configurationItem.tags['Name'] as RouteTableName,
       json_extract_scalar(configurationItem.configuration, '$.associations[0].subnetId') as SubnetAssociation1,
       json_extract_scalar(configurationItem.configuration, '$.associations[1].subnetId') as SubnetAssociation2,
       json_extract_scalar(configurationItem.configuration, '$.vpcId') as VpcId
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
WHERE dt = 'latest'
AND configurationItem.resourceType = 'AWS::EC2::RouteTable'
AND (configurationItem.awsRegion = 'us-east-1' OR configurationItem.awsRegion = 'us-west-2')
ORDER BY AccountID

## QuickSight ##
CREATE OR REPLACE VIEW Inventario_RouteTable AS
SELECT DISTINCT
"configurationItem"."configurationitemcapturetime" "CreationTime"
,"configurationItem"."resourceType" "ResourceType"
,"accountid" "AccountID"
,"configurationItem"."tags"['Environment'] "Environment"
,"configurationItem"."awsRegion" "Region"
,"configurationItem"."resourceId" "RouteTableID"
,"configurationItem"."tags"['Name'] "RouteTableName"
,"json_extract_scalar"("configurationItem"."configuration", '$.associations[0].subnetId') "SubnetAssociation1"
,"json_extract_scalar"("configurationItem"."configuration", '$.associations[1].subnetId') "SubnetAssociation2"
,"json_extract_scalar"("configurationItem"."configuration", '$.vpcId') "VpcID"
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST("configurationitems") t (configurationItem)
WHERE (("dt" = 'latest') AND ("configurationItem"."resourcetype" = 'AWS::EC2::RouteTable') AND ("configurationItem"."awsRegion" = 'us-east-1' OR "configurationItem"."awsRegion" = 'us-west-2'))
ORDER BY AccountID


#Endpoint
## Athena ##
SELECT configurationItem.configurationItemCaptureTime as CreationTime,
       configurationItem.resourceType as ResourceType,
       accountid as AccountID,
       configurationItem.tags['Environment'] as Environment,
       configurationItem.awsRegion as Region,
       configurationItem.resourceId as EndpointID,
       configurationItem.tags['Name'] as EndpointName,
       json_extract_scalar(configurationItem.configuration, '$.vpcId') as VpcID,
       json_extract_scalar(configurationItem.configuration, '$.serviceName') as ServiceName,
       json_extract_scalar(configurationItem.configuration, '$.vpcEndpointType') as VpcEndpointType,
       json_extract_scalar(configurationItem.configuration, '$.subnetIds[0]') as SubnetId1,
       json_extract_scalar(configurationItem.configuration, '$.subnetIds[1]') as SubnetId2,
       json_extract_scalar(configurationItem.configuration, '$.networkInterfaceIds[0]') as NetworkInterfaceId1,
       json_extract_scalar(configurationItem.configuration, '$.networkInterfaceIds[1]') as NetworkInterfaceId2,
       json_extract_scalar(configurationItem.configuration, '$.groups[0].groupId') as SecurityGroupID
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
WHERE dt = 'latest'
AND configurationItem.resourceType = 'AWS::EC2::VPCEndpoint'
AND (configurationItem.awsRegion = 'us-east-1' OR configurationItem.awsRegion = 'us-west-2')
ORDER BY AccountID

## QuickSight ##
CREATE OR REPLACE VIEW Inventario_Endpoint AS
SELECT DISTINCT
"configurationItem"."configurationitemcapturetime" "CreationTime"
,"configurationItem"."resourceType" "ResourceType"
,"accountid" "AccountID"
,"configurationItem"."tags"['Environment'] "Environment"
,"configurationItem"."awsRegion" "Region"
,"configurationItem"."resourceId" "EndpointID"
,"configurationItem"."tags"['Name'] "EndpointName"
,"json_extract_scalar"("configurationItem"."configuration", '$.vpcId') "VpcID"
,"json_extract_scalar"("configurationItem"."configuration", '$.serviceName') "ServiceName"
,"json_extract_scalar"("configurationItem"."configuration", '$.vpcEndpointType') "VpcEndpointType"
,"json_extract_scalar"("configurationItem"."configuration", '$.subnetIds[0]') "SubnetId1"
,"json_extract_scalar"("configurationItem"."configuration", '$.subnetIds[1]') "SubnetId2"
,"json_extract_scalar"("configurationItem"."configuration", '$.networkInterfaceIds[0]') "NetworkInterfaceId1"
,"json_extract_scalar"("configurationItem"."configuration", '$.networkInterfaceIds[1]') "NetworkInterfaceId2"
,"json_extract_scalar"("configurationItem"."configuration", '$.groups[0].groupId') "SecurityGroupID"
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST("configurationitems") t (configurationItem)
WHERE (("dt" = 'latest') AND ("configurationItem"."resourcetype" = 'AWS::EC2::VPCEndpoint') AND ("configurationItem"."awsRegion" = 'us-east-1' OR "configurationItem"."awsRegion" = 'us-west-2'))
ORDER BY AccountID


#SecurityGroups
## Athena ##
SELECT configurationItem.configurationItemCaptureTime as CreationTime,
       configurationItem.resourceType as ResourceType,
       accountid as AccountID,
       configurationItem.tags['Environment'] as Environment,
       configurationItem.awsRegion as Region,
       configurationItem.resourceId as SecurityGroupID,
       configurationItem.tags['Name'] as Name,
       configurationItem.resourceName as SecurityGroupName,
       json_extract_scalar(configurationItem.configuration, '$.vpcId') as VpcID,
       json_extract_scalar(configurationItem.configuration, '$.description') as Description
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
WHERE dt = 'latest'
AND configurationItem.resourceType = 'AWS::EC2::SecurityGroup'
AND (configurationItem.awsRegion = 'us-east-1' OR configurationItem.awsRegion = 'us-west-2')
AND NOT configurationItem.tags['Name'] = 'controltower'
ORDER BY AccountID

## QuickSight ##
CREATE OR REPLACE VIEW Inventario_SecurityGroup AS
SELECT DISTINCT
"configurationItem"."configurationitemcapturetime" "CreationTime"
,"configurationItem"."resourceType" "ResourceType"
,"accountid" "AccountID"
,"configurationItem"."tags"['Environment'] "Environment"
,"configurationItem"."awsRegion" "Region"
,"configurationItem"."resourceId" "SecurityGroupID"
,"configurationItem"."tags"['Name'] "Name"
,"configurationItem"."resourceName" "SecurityGroupName"
,"json_extract_scalar"("configurationItem"."configuration", '$.vpcId') "VpcID"
,"json_extract_scalar"("configurationItem"."configuration", '$.description') "Description"
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST("configurationitems") t (configurationItem)
WHERE (("dt" = 'latest') AND ("configurationItem"."resourcetype" = 'AWS::EC2::SecurityGroup') AND ("configurationItem"."awsRegion" = 'us-east-1' OR "configurationItem"."awsRegion" = 'us-west-2'))
ORDER BY AccountID


#EC2
## Athena ##
SELECT json_extract_scalar(configurationItem.configuration, '$.networkInterfaces[0].attachment.attachTime') as CreationTime,
       configurationItem.resourceType as ResourceType,
       accountid as AccountID,
       configurationItem.tags['Environment'] as Environment,
       configurationItem.awsRegion as Region,
       configurationItem.resourceId as InstanceID,
       configurationItem.tags['Name'] as InstanceName,
       json_extract_scalar(configurationItem.configuration, '$.instanceType') as InstanceType,
       configurationItem.availabilityZone as AvailabilityZone,
       json_extract_scalar(configurationItem.configuration, '$.privateIpAddress') as PrivateIpAddress,
       json_extract_scalar(configurationItem.configuration, '$.networkInterfaces[0].macAddress') as MacAddress,
       json_extract_scalar(configurationItem.configuration, '$.networkInterfaces[0].networkInterfaceId') as NetworkInterfaceID,
       json_extract_scalar(configurationItem.configuration, '$.securityGroups[0].groupId') as SecurityGroupID,
       json_extract_scalar(configurationItem.configuration, '$.vpcId') as VpcID,
       json_extract_scalar(configurationItem.configuration, '$.subnetId') as SubnetID,
       json_extract_scalar(configurationItem.configuration, '$.architecture') as Architecture,
       json_extract_scalar(configurationItem.configuration, '$.virtualizationType') as VirtualizationType,
       json_extract_scalar(configurationItem.configuration, '$.hypervisor') as Hypervisor,
       json_extract_scalar(configurationItem.configuration, '$.platform') as Platform,
       json_extract_scalar(configurationItem.configuration, '$.cpuOptions.coreCount') as CoreCount,
       json_extract_scalar(configurationItem.configuration, '$.cpuOptions.threadsPerCore') as ThreadsPerCore,
       json_extract_scalar(configurationItem.configuration, '$.rootDeviceName') as RootDeviceName,
       json_extract_scalar(configurationItem.configuration, '$.rootDeviceType') as RootDeviceType,
       json_extract_scalar(configurationItem.configuration, '$.imageId') as ImageID
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
WHERE dt = 'latest'
AND configurationItem.resourceType = 'AWS::EC2::Instance'
ORDER BY AccountID

## QuickSight ##
CREATE OR REPLACE VIEW Inventario_EC2 AS
SELECT DISTINCT
"json_extract_scalar"("configurationItem"."configuration", '$.networkInterfaces[0].attachment.attachTime') "CreationTime"
,"configurationItem"."resourceType" "ResourceType"
,"accountid" "AccountID"
,"configurationItem"."tags"['Environment'] "Environment"
,"configurationItem"."awsRegion" "Region"
,"configurationItem"."resourceId" "InstanceID"
,"configurationItem"."tags"['Name'] "InstanceName"
,"json_extract_scalar"("configurationItem"."configuration", '$.instanceType') "InstanceType"
,"configurationItem"."availabilityZone" "AvailabilityZone"
,"json_extract_scalar"("configurationItem"."configuration", '$.privateIpAddress') "PrivateIpAddress"
,"json_extract_scalar"("configurationItem"."configuration", '$.networkInterfaces[0].macAddress') "MacAddress"
,"json_extract_scalar"("configurationItem"."configuration", '$.networkInterfaces[0].networkInterfaceId') "NetworkInterfaceID"
,"json_extract_scalar"("configurationItem"."configuration", '$.securityGroups[0].groupId') "SecurityGroupID"
,"json_extract_scalar"("configurationItem"."configuration", '$.vpcId') "VpcID"
,"json_extract_scalar"("configurationItem"."configuration", '$.subnetId') "SubnetID"
,"json_extract_scalar"("configurationItem"."configuration", '$.architecture') "Architecture"
,"json_extract_scalar"("configurationItem"."configuration", '$.virtualizationType') "VirtualizationType"
,"json_extract_scalar"("configurationItem"."configuration", '$.hypervisor') "Hypervisor"
,"json_extract_scalar"("configurationItem"."configuration", '$.platform') "Platform"
,"json_extract_scalar"("configurationItem"."configuration", '$.cpuOptions.coreCount') "CoreCount"
,"json_extract_scalar"("configurationItem"."configuration", '$.cpuOptions.threadsPerCore') "ThreadsPerCore"
,"json_extract_scalar"("configurationItem"."configuration", '$.rootDeviceName') "RootDeviceName"
,"json_extract_scalar"("configurationItem"."configuration", '$.rootDeviceType') "RootDeviceType"
,"json_extract_scalar"("configurationItem"."configuration", '$.imageId') "ImageID"
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST("configurationitems") t (configurationItem)
WHERE (("dt" = 'latest') AND ("configurationItem"."resourcetype" = 'AWS::EC2::Instance'))
ORDER BY AccountID


#LoadBalancer
## Athena ##
SELECT configurationItem.configurationItemCaptureTime as CreationTime,
       configurationItem.resourceType as ResourceType,
       accountid as AccountID,
       configurationItem.tags['Environment'] as Environment,
       configurationItem.awsRegion as Region,
       configurationItem.resourceName as LoadBalancerName,
       json_extract_scalar(configurationItem.configuration, '$.dNSName') as DNSName,
       json_extract_scalar(configurationItem.configuration, '$.type') as Type,
       json_extract_scalar(configurationItem.configuration, '$.scheme') as Scheme,
       json_extract_scalar(configurationItem.configuration, '$.canonicalHostedZoneId') as CanonicalHostedZoneID,
       json_extract_scalar(configurationItem.configuration, '$.vpcId') as VpcID,
       json_extract_scalar(configurationItem.configuration, '$.availabilityZones[0].subnetId') as SubnetId1,
       json_extract_scalar(configurationItem.configuration, '$.availabilityZones[1].subnetId') as SubnetId2,
       json_extract_scalar(configurationItem.configuration, '$.securityGroups[0]') as SecurityGroupID
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
WHERE dt = 'latest'
AND configurationItem.resourceType = 'AWS::ElasticLoadBalancingV2::LoadBalancer'
ORDER BY AccountID

## QuickSight ##
CREATE OR REPLACE VIEW Inventario_LoadBalancer AS
SELECT DISTINCT
"configurationItem"."configurationitemcapturetime" "CreationTime"
,"configurationItem"."resourceType" "ResourceType"
,"accountid" "AccountID"
,"configurationItem"."tags"['Environment'] "Environment"
,"configurationItem"."awsRegion" "Region"
,"configurationItem"."resourceName" "LoadBalancerName"
,"json_extract_scalar"("configurationItem"."configuration", '$.dNSName') "DNSName"
,"json_extract_scalar"("configurationItem"."configuration", '$.type') "Type"
,"json_extract_scalar"("configurationItem"."configuration", '$.scheme') "Scheme"
,"json_extract_scalar"("configurationItem"."configuration", '$.canonicalHostedZoneId') "CanonicalHostedZoneID"
,"json_extract_scalar"("configurationItem"."configuration", '$.vpcId') "VpcID"
,"json_extract_scalar"("configurationItem"."configuration", '$.availabilityZones[0].subnetId') "SubnetId1"
,"json_extract_scalar"("configurationItem"."configuration", '$.availabilityZones[0].subnetId') "SubnetId2"
,"json_extract_scalar"("configurationItem"."configuration", '$.securityGroups[0]') "SecurityGroupID"
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST("configurationitems") t (configurationItem)
WHERE (("dt" = 'latest') AND ("configurationItem"."resourcetype" = 'AWS::ElasticLoadBalancingV2::LoadBalancer'))
ORDER BY AccountID


#RDS
## Athena ##
SELECT json_extract_scalar(configurationItem.configuration, '$.instanceCreateTime') as CreationTime,
       configurationItem.resourceType as ResourceType,
       accountid as AccountID,
       configurationItem.tags['Environment'] as Environment,
       configurationItem.awsRegion as Region,
       configurationItem.resourceName as DBidentifier,
       json_extract_scalar(configurationItem.configuration, '$.dBInstanceClass') as DBInstanceClass,
       json_extract_scalar(configurationItem.configuration, '$.endpoint.address') as Endpoint,
       json_extract_scalar(configurationItem.configuration, '$.endpoint.port') as Port,
       json_extract_scalar(configurationItem.configuration, '$.engine') as Engine,
       json_extract_scalar(configurationItem.configuration, '$.engineVersion') as EngineVersion,
       json_extract_scalar(configurationItem.configuration, '$.dBName') as DBName,
       json_extract_scalar(configurationItem.configuration, '$.licenseModel') as LicenseModel,
       json_extract_scalar(configurationItem.configuration, '$.storageType') as StorageType,
       json_extract_scalar(configurationItem.configuration, '$.allocatedStorage') as AllocatedStorageGiB,
       json_extract_scalar(configurationItem.configuration, '$.iops') as IOPS,
       json_extract_scalar(configurationItem.configuration, '$.storageEncrypted') as StorageEncrypted,
       json_extract_scalar(configurationItem.configuration, '$.publiclyAccessible') as PubliclyAccessible,
       json_extract_scalar(configurationItem.configuration, '$.deletionProtection') as DeletionProtection,
       json_extract_scalar(configurationItem.configuration, '$.multiAZ') as MultiAZ,
       json_extract_scalar(configurationItem.configuration, '$.dBSubnetGroup.vpcId') as VpcID,
       configurationItem.availabilityZone as AvailabilityZone,
       json_extract_scalar(configurationItem.configuration, '$.vpcSecurityGroups[0].vpcSecurityGroupId') as VpcSecurityGroups,
       json_extract_scalar(configurationItem.configuration, '$.dBSubnetGroup.dBSubnetGroupName') as SubnetGroupName,
       json_extract_scalar(configurationItem.configuration, '$.dBParameterGroups[0].dBParameterGroupName') as DBParameterGroupName,
       json_extract_scalar(configurationItem.configuration, '$.optionGroupMemberships[0].optionGroupName') as OptionGroupName,
       json_extract_scalar(configurationItem.configuration, '$.characterSetName') as CharacterSetName,
       json_extract_scalar(configurationItem.configuration, '$.ncharCharacterSetName') as NcharCharacterSetName
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
WHERE dt = 'latest'
AND configurationItem.resourceType = 'AWS::RDS::DBInstance'
ORDER BY AccountID

## QuickSight ##
CREATE OR REPLACE VIEW Inventario_RDS AS
SELECT DISTINCT
"json_extract_scalar"("configurationItem"."configuration", '$.instanceCreateTime') "CreationTime"
,"configurationItem"."resourceType" "ResourceType"
,"accountid" "AccountID"
,"configurationItem"."tags"['Environment'] "Environment"
,"configurationItem"."awsRegion" "Region"
,"configurationItem"."resourceName" "DBidentifier"
,"json_extract_scalar"("configurationItem"."configuration", '$.dBInstanceClass') "DBInstanceClass"
,"json_extract_scalar"("configurationItem"."configuration", '$.endpoint.address') "Endpoint"
,"json_extract_scalar"("configurationItem"."configuration", '$.endpoint.port') "Port"
,"json_extract_scalar"("configurationItem"."configuration", '$.engine') "Engine"
,"json_extract_scalar"("configurationItem"."configuration", '$.engineVersion') "EngineVersion"
,"json_extract_scalar"("configurationItem"."configuration", '$.dBName') "DBName"
,"json_extract_scalar"("configurationItem"."configuration", '$.licenseModel') "LicenseModel"
,"json_extract_scalar"("configurationItem"."configuration", '$.storageType') "StorageType"
,"json_extract_scalar"("configurationItem"."configuration", '$.allocatedStorage') "AllocatedStorageGiB"
,"json_extract_scalar"("configurationItem"."configuration", '$.iops') "IOPS"
,"json_extract_scalar"("configurationItem"."configuration", '$.storageEncrypted') "StorageEncrypted"
,"json_extract_scalar"("configurationItem"."configuration", '$.publiclyAccessible') "PubliclyAccessible"
,"json_extract_scalar"("configurationItem"."configuration", '$.deletionProtection') "DeletionProtection"
,"json_extract_scalar"("configurationItem"."configuration", '$.multiAZ') "MultiAZ"
,"json_extract_scalar"("configurationItem"."configuration", '$.dBSubnetGroup.vpcId') "VpcID"
,"configurationItem"."availabilityZone" "AvailabilityZone"
,"json_extract_scalar"("configurationItem"."configuration", '$.vpcSecurityGroups[0].vpcSecurityGroupId') "VpcSecurityGroups"
,"json_extract_scalar"("configurationItem"."configuration", '$.dBSubnetGroup.dBSubnetGroupName') "SubnetGroupName"
,"json_extract_scalar"("configurationItem"."configuration", '$.dBParameterGroups[0].dBParameterGroupName') "DBParameterGroupName"
,"json_extract_scalar"("configurationItem"."configuration", '$.optionGroupMemberships[0].optionGroupName') "OptionGroupName"
,"json_extract_scalar"("configurationItem"."configuration", '$.characterSetName') "CharacterSetName"
,"json_extract_scalar"("configurationItem"."configuration", '$.ncharCharacterSetName') "NcharCharacterSetName"
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST("configurationitems") t (configurationItem)
WHERE (("dt" = 'latest') AND ("configurationItem"."resourcetype" = 'AWS::RDS::DBInstance'))
ORDER BY AccountID


#S3
## Athena ##
SELECT json_extract_scalar(configurationItem.configuration, '$.creationDate') as CreationTime,
       configurationItem.resourceType as ResourceType,
       accountid as AccountID,
       configurationItem.tags['Environment'] as Environment,
       configurationItem.awsRegion as Region,
       configurationItem.resourceName as Name,
       json_extract_scalar(configurationItem.supplementaryConfiguration['BucketVersioningConfiguration'], '$.status') as BucketVersioningConfiguration,
       json_extract_scalar(configurationItem.supplementaryConfiguration['ServerSideEncryptionConfiguration'], '$.rules[0].applyServerSideEncryptionByDefault.sseAlgorithm') as ServerSideEncryptionConfiguration,
       json_extract_scalar(configurationItem.supplementaryConfiguration['PublicAccessBlockConfiguration'], '$.blockPublicAcls') as BlockPublicAcls,
       json_extract_scalar(configurationItem.supplementaryConfiguration['PublicAccessBlockConfiguration'], '$.ignorePublicAcls') as IgnorePublicAcls,
       json_extract_scalar(configurationItem.supplementaryConfiguration['PublicAccessBlockConfiguration'], '$.blockPublicPolicy') as BlockPublicPolicy,
       json_extract_scalar(configurationItem.supplementaryConfiguration['PublicAccessBlockConfiguration'], '$.restrictPublicBuckets') as RestrictPublicBuckets
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
WHERE dt = 'latest'
AND configurationItem.resourceType = 'AWS::S3::Bucket'
AND NOT configurationItem.resourceName = 'aws-controltower'
ORDER BY AccountID

## QuickSight ##
CREATE OR REPLACE VIEW Inventario_S3 AS
SELECT DISTINCT
"json_extract_scalar"("configurationItem"."configuration", '$.creationDate') "CreationTime"
,"configurationItem"."resourceType" "ResourceType"
,"accountid" "AccountID"
,"configurationItem"."tags"['Environment'] "Environment"
,"configurationItem"."awsRegion" "Region"
,"configurationItem"."resourceName" "Name"
,"json_extract_scalar"("configurationItem"."supplementaryConfiguration"['BucketVersioningConfiguration'], '$.status') "BucketVersioningConfiguration"
,"json_extract_scalar"("configurationItem"."supplementaryConfiguration"['ServerSideEncryptionConfiguration'], '$.rules[0].applyServerSideEncryptionByDefault.sseAlgorithm') "ServerSideEncryptionConfiguration"
,"json_extract_scalar"("configurationItem"."supplementaryConfiguration"['PublicAccessBlockConfiguration'], '$.blockPublicAcls') "BlockPublicAcls"
,"json_extract_scalar"("configurationItem"."supplementaryConfiguration"['PublicAccessBlockConfiguration'], '$.ignorePublicAcls') "IgnorePublicAcls"
,"json_extract_scalar"("configurationItem"."supplementaryConfiguration"['PublicAccessBlockConfiguration'], '$.blockPublicPolicy') "BlockPublicPolicy"
,"json_extract_scalar"("configurationItem"."supplementaryConfiguration"['PublicAccessBlockConfiguration'], '$.restrictPublicBuckets') "RestrictPublicBuckets"
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST("configurationitems") t (configurationItem)
WHERE (("dt" = 'latest') AND ("configurationItem"."resourcetype" = 'AWS::S3::Bucket'))
ORDER BY AccountID


#REST API
## Athena ##
SELECT json_extract_scalar(configurationItem.configuration, '$.createdDate') as CreationTime,
       configurationItem.resourceType as ResourceType,
       accountid as AccountID,
       configurationItem.tags['Environment'] as Environment,
       configurationItem.awsRegion as Region,
       configurationItem.resourceName as ApiName,
       json_extract_scalar(configurationItem.configuration, '$.id') as ApiID,
       json_extract_scalar(configurationItem.configuration, '$.endpointConfiguration.types[0]') as EndpointType
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
WHERE dt = 'latest'
AND configurationItem.resourceType = 'AWS::ApiGateway::RestApi'
ORDER BY AccountID

## QuickSight ##
CREATE OR REPLACE VIEW Inventario_APIGateway AS
SELECT DISTINCT
"json_extract_scalar"("configurationItem"."configuration", '$.createdDate') "CreationTime"
,"configurationItem"."resourceType" "ResourceType"
,"accountid" "AccountID"
,"configurationItem"."tags"['Environment'] "Environment"
,"configurationItem"."awsRegion" "Region"
,"configurationItem"."resourceName" "ApiName"
,"json_extract_scalar"("configurationItem"."configuration", '$.id') "ApiID"
,"json_extract_scalar"("configurationItem"."configuration", '$.endpointConfiguration.types[0]') "EndpointType"
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST("configurationitems") t (configurationItem)
WHERE (("dt" = 'latest') AND ("configurationItem"."resourcetype" = 'AWS::ApiGateway::RestApi'))
ORDER BY AccountID


#Lambda
## Athena ##
SELECT json_extract_scalar(configurationItem.configuration, '$.lastModified') as LastModified,
       configurationItem.resourceType as ResourceType,
       accountid as AccountID,
       configurationItem.tags['Environment'] as Environment,
       configurationItem.awsRegion as Region,
       configurationItem.resourceName as FunctionName,
       json_extract_scalar(configurationItem.configuration, '$.runtime') as Runtime,
       json_extract_scalar(configurationItem.configuration, '$.codeSize') as CodeSizeByte,
       json_extract_scalar(configurationItem.configuration, '$.timeout') as TimeoutSeconds,
       json_extract_scalar(configurationItem.configuration, '$.memorySize') as MemorySizeMB,
       json_extract_scalar(configurationItem.configuration, '$.handler') as Handler,
       json_extract_scalar(configurationItem.configuration, '$.role') as Role,
       json_extract_scalar(configurationItem.configuration, '$.vpcConfig.subnetIds[0]') as SubnetID1,
       json_extract_scalar(configurationItem.configuration, '$.vpcConfig.subnetIds[1]') as SubnetID2,
       json_extract_scalar(configurationItem.configuration, '$.vpcConfig.securityGroupIds[0]') as SecurityGroupID,
       json_extract_scalar(configurationItem.configuration, '$.description') as Description
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
WHERE dt = 'latest'
AND configurationItem.resourceType = 'AWS::Lambda::Function'
AND NOT configurationItem.resourceName = 'aws-controltower-NotificationForwarder'
ORDER BY AccountID

## QuickSight ##
CREATE OR REPLACE VIEW Inventario_Lambda AS
SELECT DISTINCT
"json_extract_scalar"("configurationItem"."configuration", '$.lastModified') "LastModified"
,"configurationItem"."resourceType" "ResourceType"
,"accountid" "AccountID"
,"configurationItem"."tags"['Environment'] "Environment"
,"configurationItem"."awsRegion" "Region"
,"configurationItem"."resourceName" "FunctionName"
,"json_extract_scalar"("configurationItem"."configuration", '$.runtime') "Runtime"
,"json_extract_scalar"("configurationItem"."configuration", '$.codeSize') "CodeSizeByte"
,"json_extract_scalar"("configurationItem"."configuration", '$.timeout') "TimeoutSeconds"
,"json_extract_scalar"("configurationItem"."configuration", '$.memorySize') "MemorySizeMB"
,"json_extract_scalar"("configurationItem"."configuration", '$.handler') "Handler"
,"json_extract_scalar"("configurationItem"."configuration", '$.role') "Role"
,"json_extract_scalar"("configurationItem"."configuration", '$.vpcConfig.subnetIds[0]') "SubnetID1"
,"json_extract_scalar"("configurationItem"."configuration", '$.vpcConfig.subnetIds[1]') "SubnetID2"
,"json_extract_scalar"("configurationItem"."configuration", '$.vpcConfig.securityGroupIds[0]') "SecurityGroupID"
,"json_extract_scalar"("configurationItem"."configuration", '$.description') "Description"
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST("configurationitems") t (configurationItem)
WHERE (("dt" = 'latest') AND ("configurationItem"."resourcetype" = 'AWS::Lambda::Function') AND NOT ("configurationItem"."resourceName" = 'aws-controltower-NotificationForwarder'))
ORDER BY AccountID


#IAM
## Athena ##
SELECT json_extract_scalar(configurationItem.configuration, '$.createDate') as CreationTime,
       configurationItem.resourceType as ResourceType,
       accountid as AccountID,
       configurationItem.tags['Environment'] as Environment,
       json_extract_scalar(configurationItem.configuration, '$.userName') as UserName,
       json_extract_scalar(configurationItem.configuration, '$.groupList[0]') as GroupName,
       json_extract_scalar(configurationItem.configuration, '$.userId') as UserID,
       configurationItem.tags['Nombre'] as Nombre,
       configurationItem.tags['Correo'] as Correo,
       configurationItem.tags['Telefono'] as Telefono
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
WHERE dt = 'latest'
AND configurationItem.resourceType = 'AWS::IAM::User'
AND region = 'us-east-1'
ORDER BY AccountID

## QuickSight ##
CREATE OR REPLACE VIEW Inventario_IAM AS
SELECT DISTINCT
"json_extract_scalar"("configurationItem"."configuration", '$.createDate') "CreationTime"
,"configurationItem"."resourceType" "ResourceType"
,"accountid" "AccountID"
,"configurationItem"."tags"['Environment'] "Environment"
,"json_extract_scalar"("configurationItem"."configuration", '$.userName') "UserName"
,"json_extract_scalar"("configurationItem"."configuration", '$.groupList[0]') "GroupName"
,"json_extract_scalar"("configurationItem"."configuration", '$.userId') "UserID"
,"configurationItem"."tags"['Nombre'] "Nombre"
,"configurationItem"."tags"['Correo'] "Correo"
,"configurationItem"."tags"['Telefono'] "Telefono"
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST("configurationitems") t (configurationItem)
WHERE (("dt" = 'latest') AND ("configurationItem"."resourcetype" = 'AWS::IAM::User') AND ("region" = 'us-east-1'))
ORDER BY AccountID


#ECS Cluster
## Athena ##
SELECT configurationItem.resourceType as ResourceType,
       accountid as AccountID,
       configurationItem.tags['Environment'] as Environment,
       configurationItem.awsRegion as Region,
       json_extract_scalar(configurationItem.configuration, '$.ClusterName') as ClusterName
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
WHERE dt = 'latest'
AND configurationItem.resourceType = 'AWS::ECS::Cluster'
ORDER BY AccountID

## QuickSight ##
CREATE OR REPLACE VIEW Inventario_ECS_Cluster AS
SELECT DISTINCT
"configurationItem"."configurationitemcapturetime" "LastModified"
,"configurationItem"."resourceType" "ResourceType"
,"accountid" "AccountID"
,"configurationItem"."tags"['Environment'] "Environment"
,"configurationItem"."awsRegion" "Region"
,"json_extract_scalar"("configurationItem"."configuration", '$.ClusterName') "ClusterName"
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST("configurationitems") t (configurationItem)
WHERE (("dt" = 'latest') AND ("configurationItem"."resourcetype" = 'AWS::ECS::Cluster'))
ORDER BY AccountID


#ECS Service
## Athena ##
SELECT configurationItem.resourceType as ResourceType,
       accountid as AccountID,
       configurationItem.tags['Environment'] as Environment,
       configurationItem.awsRegion as Region,
       json_extract_scalar(configurationItem.configuration, '$.ServiceName') as ServiceName,
       json_extract_scalar(configurationItem.configuration, '$.LaunchType') as LaunchType,
       json_extract_scalar(configurationItem.configuration, '$.PlatformVersion') as PlatformVersion,
       json_extract_scalar(configurationItem.configuration, '$.NetworkConfiguration.AwsvpcConfiguration.SecurityGroups[0]') as SecurityGroup,
       json_extract_scalar(configurationItem.configuration, '$.Cluster') as Cluster
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
WHERE dt = 'latest'
AND configurationItem.resourceType = 'AWS::ECS::Service'
ORDER BY AccountID

## QuickSight ##
CREATE OR REPLACE VIEW Inventario_ECS_Services AS
SELECT DISTINCT
"configurationItem"."configurationitemcapturetime" "LastModified"
,"configurationItem"."resourceType" "ResourceType"
,"accountid" "AccountID"
,"configurationItem"."tags"['Environment'] "Environment"
,"configurationItem"."awsRegion" "Region"
,"json_extract_scalar"("configurationItem"."configuration", '$.ServiceName') "ServiceName"
,"json_extract_scalar"("configurationItem"."configuration", '$.LaunchType') "LaunchType"
,"json_extract_scalar"("configurationItem"."configuration", '$.PlatformVersion') "PlatformVersion"
,"json_extract_scalar"("configurationItem"."configuration", '$.NetworkConfiguration.AwsvpcConfiguration.SecurityGroups[0]') "SecurityGroup"
,"json_extract_scalar"("configurationItem"."configuration", '$.Cluster') "Cluster"
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST("configurationitems") t (configurationItem)
WHERE (("dt" = 'latest') AND ("configurationItem"."resourcetype" = 'AWS::ECS::Service'))
ORDER BY AccountID


#EFS
## Athena ##
SELECT configurationItem.resourceType as ResourceType,
       accountid as AccountID,
       configurationItem.tags['Environment'] as Environment,
       configurationItem.awsRegion as Region,
       configurationItem.resourceId as FileSystemID,
       configurationItem.tags['Name'] as FileSystemName,
       json_extract_scalar(configurationItem.configuration, '$.Encrypted') as Encrypted,
       json_extract_scalar(configurationItem.configuration, '$.PerformanceMode') as PerformanceMode,
       json_extract_scalar(configurationItem.configuration, '$.ThroughputMode') as ThroughputMode,
       json_extract_scalar(configurationItem.configuration, '$.LifecyclePolicies[0].TransitionToIA') as LifecyclePolicies,
       json_extract_scalar(configurationItem.configuration, '$.BackupPolicy.Status') as BackupPolicy
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
WHERE dt = 'latest'
AND configurationItem.resourceType = 'AWS::EFS::FileSystem'
ORDER BY AccountID

## QuickSight ##
CREATE OR REPLACE VIEW Inventario_EFS AS
SELECT DISTINCT
"configurationItem"."configurationitemcapturetime" "LastModified"
,"configurationItem"."resourceType" "ResourceType"
,"accountid" "AccountID"
,"configurationItem"."tags"['Environment'] "Environment"
,"configurationItem"."awsRegion" "Region"
,"configurationItem"."resourceId" "FileSystemID"
,"configurationItem"."tags"['Name'] "FileSystemName"
,"json_extract_scalar"("configurationItem"."configuration", '$.Encrypted') "Encrypted"
,"json_extract_scalar"("configurationItem"."configuration", '$.PerformanceMode') "PerformanceMode"
,"json_extract_scalar"("configurationItem"."configuration", '$.ThroughputMode') "ThroughputMode"
,"json_extract_scalar"("configurationItem"."configuration", '$.LifecyclePolicies[0].TransitionToIA') "LifecyclePolicies"
,"json_extract_scalar"("configurationItem"."configuration", '$.BackupPolicy.Status') "BackupPolicy"
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST("configurationitems") t (configurationItem)
WHERE (("dt" = 'latest') AND ("configurationItem"."resourcetype" = 'AWS::EFS::FileSystem'))
ORDER BY AccountID


#TransitGateway
## Athena ##
SELECT configurationItem.resourceType as ResourceType,
       accountid as AccountID,
       configurationItem.tags['Environment'] as Environment,
       configurationItem.awsRegion as Region,
       configurationItem.resourceId as TransitGatewayID,
       json_extract_scalar(configurationItem.configuration, '$.Description') as Description,
       json_extract_scalar(configurationItem.configuration, '$.DefaultRouteTablePropagation') as DefaultRouteTablePropagation,
       json_extract_scalar(configurationItem.configuration, '$.AutoAcceptSharedAttachments') as AutoAcceptSharedAttachments,
       json_extract_scalar(configurationItem.configuration, '$.DefaultRouteTableAssociation') as DefaultRouteTableAssociation,
       json_extract_scalar(configurationItem.configuration, '$.AssociationDefaultRouteTableId') as AssociationDefaultRouteTableId,
       json_extract_scalar(configurationItem.configuration, '$.PropagationDefaultRouteTableId') as PropagationDefaultRouteTableId,
       json_extract_scalar(configurationItem.configuration, '$.VpnEcmpSupport') as VpnEcmpSupport,
       json_extract_scalar(configurationItem.configuration, '$.DnsSupport') as DnsSupport,
       json_extract_scalar(configurationItem.configuration, '$.MulticastSupport') as MulticastSupport,
       json_extract_scalar(configurationItem.configuration, '$.AmazonSideAsn') as AmazonSideAsn
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
WHERE dt = 'latest'
AND configurationItem.resourceType = 'AWS::EC2::TransitGateway'
ORDER BY AccountID

## QuickSight ##
CREATE OR REPLACE VIEW Inventario_TGW AS
SELECT DISTINCT
"configurationItem"."configurationitemcapturetime" "LastModified"
,"configurationItem"."resourceType" "ResourceType"
,"accountid" "AccountID"
,"configurationItem"."tags"['Environment'] "Environment"
,"configurationItem"."awsRegion" "Region"
,"configurationItem"."resourceId" "TransitGatewayID"
,"json_extract_scalar"("configurationItem"."configuration", '$.Description') "Description"
,"json_extract_scalar"("configurationItem"."configuration", '$.DefaultRouteTablePropagation') "DefaultRouteTablePropagation"
,"json_extract_scalar"("configurationItem"."configuration", '$.AutoAcceptSharedAttachments') "AutoAcceptSharedAttachments"
,"json_extract_scalar"("configurationItem"."configuration", '$.DefaultRouteTableAssociation') "DefaultRouteTableAssociation"
,"json_extract_scalar"("configurationItem"."configuration", '$.AssociationDefaultRouteTableId') "AssociationDefaultRouteTableId"
,"json_extract_scalar"("configurationItem"."configuration", '$.PropagationDefaultRouteTableId') "PropagationDefaultRouteTableId"
,"json_extract_scalar"("configurationItem"."configuration", '$.VpnEcmpSupport') "VpnEcmpSupport"
,"json_extract_scalar"("configurationItem"."configuration", '$.DnsSupport') "DnsSupport"
,"json_extract_scalar"("configurationItem"."configuration", '$.MulticastSupport') "MulticastSupport"
,"json_extract_scalar"("configurationItem"."configuration", '$.AmazonSideAsn') "AmazonSideAsn"
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST("configurationitems") t (configurationItem)
WHERE (("dt" = 'latest') AND ("configurationItem"."resourcetype" = 'AWS::EC2::TransitGateway'))
ORDER BY AccountID


#ECR
## Athena ##
SELECT configurationItem.configurationItemCaptureTime as LastModified,
       configurationItem.resourceType as ResourceType,
       accountid as AccountID,
       configurationItem.tags['Environment'] as Environment,
       configurationItem.awsRegion as Region,
       json_extract_scalar(configurationItem.configuration, '$.RepositoryName') as RepositoryName,
       json_extract_scalar(configurationItem.configuration, '$.ImageScanningConfiguration.ScanOnPush') as ScanOnPush,
       json_extract_scalar(configurationItem.configuration, '$.ImageTagMutability') as ImageTagMutability
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
WHERE dt = 'latest'
AND configurationItem.resourceType = 'AWS::ECR::Repository'
ORDER BY AccountID

## QuickSight ##
CREATE OR REPLACE VIEW Inventario_ECR AS
SELECT DISTINCT
"configurationItem"."configurationitemcapturetime" "LastModified"
,"configurationItem"."resourceType" "ResourceType"
,"accountid" "AccountID"
,"configurationItem"."tags"['Environment'] "Environment"
,"configurationItem"."awsRegion" "Region"
,"json_extract_scalar"("configurationItem"."configuration", '$.RepositoryName') "RepositoryName"
,"json_extract_scalar"("configurationItem"."configuration", '$.ImageScanningConfiguration.ScanOnPush') "ScanOnPush"
,"json_extract_scalar"("configurationItem"."configuration", '$.ImageTagMutability') "ImageTagMutability"
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST("configurationitems") t (configurationItem)
WHERE (("dt" = 'latest') AND ("configurationItem"."resourcetype" = 'AWS::ECR::Repository'))
ORDER BY AccountID


#ACM
## Athena ##
SELECT json_extract_scalar(configurationItem.configuration, '$.createdAt') as CreationTime,
       configurationItem.resourceType as ResourceType,
       accountid as AccountID,
       configurationItem.tags['Environment'] as Environment,
       configurationItem.awsRegion as Region,
       json_extract_scalar(configurationItem.configuration, '$.certificateArn') as certificateArn,
       json_extract_scalar(configurationItem.configuration, '$.domainName') as domainName,
       json_extract_scalar(configurationItem.configuration, '$.serial') as serial,
       json_extract_scalar(configurationItem.configuration, '$.issuer') as issuer,
       json_extract_scalar(configurationItem.configuration, '$.status') as status,
       json_extract_scalar(configurationItem.configuration, '$.notAfter') as notAfter,
       json_extract_scalar(configurationItem.configuration, '$.keyAlgorithm') as keyAlgorithm,
       json_extract_scalar(configurationItem.configuration, '$.signatureAlgorithm') as signatureAlgorithm,
       json_extract_scalar(configurationItem.configuration, '$.type') as type,
       json_extract_scalar(configurationItem.configuration, '$.renewalSummary.renewalStatus') as renewalStatus
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
WHERE dt = 'latest'
AND configurationItem.resourceType = 'AWS::ACM::Certificate'
ORDER BY AccountID

## QuickSight ##
CREATE OR REPLACE VIEW Inventario_ACM AS
SELECT DISTINCT
"json_extract_scalar"("configurationItem"."configuration", '$.createdAt') "CreationTime"
,"json_extract_scalar"("configurationItem"."configuration", '$.notAfter') "ExpireTime"
,"configurationItem"."resourceType" "ResourceType"
,"accountid" "AccountID"
,"configurationItem"."tags"['Environment'] "Environment"
,"configurationItem"."awsRegion" "Region"
,"json_extract_scalar"("configurationItem"."configuration", '$.domainName') "domainName"
,"json_extract_scalar"("configurationItem"."configuration", '$.issuer') "issuer"
,"json_extract_scalar"("configurationItem"."configuration", '$.status') "status"
,"json_extract_scalar"("configurationItem"."configuration", '$.keyAlgorithm') "keyAlgorithm"
,"json_extract_scalar"("configurationItem"."configuration", '$.signatureAlgorithm') "signatureAlgorithm"
,"json_extract_scalar"("configurationItem"."configuration", '$.serial') "serial"
,"json_extract_scalar"("configurationItem"."configuration", '$.type') "type"
,"json_extract_scalar"("configurationItem"."configuration", '$.renewalSummary.renewalStatus') "renewalStatus"
,"json_extract_scalar"("configurationItem"."configuration", '$.certificateArn') "certificateArn"
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST("configurationitems") t (configurationItem)
WHERE (("dt" = 'latest') AND ("configurationItem"."resourcetype" = 'AWS::ACM::Certificate'))
ORDER BY AccountID


#Route53-Resolver
## Athena ##
SELECT configurationItem.resourceType as ResourceType,
       configurationItem.resourceId as resourceId,
       accountid as AccountID,
       configurationItem.tags['Environment'] as Environment,
       configurationItem.awsRegion as Region
FROM config_db.aws_config_configuration_snapshot
CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
WHERE dt = 'latest'
AND accountid = '904873416324'
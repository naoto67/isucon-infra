PROFILE := MY_ROOT
REGION := ap-northeast-1

describe_ips:
	aws ec2 describe-instances --profile ${PROFILE} --region ${REGION} \
		--filters "Name=tag:Name,Values=isucon-instance" \
		--query "Reservations[].Instances[].[InstanceId,PublicIpAddress,PrivateIpAddress]"

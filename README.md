### セットアップ

terraform.tfvars ファイルを作成
```
profile       = ${使用するaws cli キーのprofile名}
ssh_file_path = ${ec2にsshで接続するときに使用する公開鍵のファイルパス}
```

### インフラ作成

```
terraform init
terraform apply
```

### 削除

```
terraform destroy
```

.PHONY: init plan apply destroy clean fmt validate all help deploy

# デフォルトターゲット
.DEFAULT_GOAL := help

# 変数定義
AWS_REGION := ap-northeast-1
TF_VARS_FILE := terraform.tfvars

# Terraformの初期化
init:
	@echo "Terraformを初期化しています..."
	terraform init

# 変更計画の表示
plan:
	@echo "変更計画を表示しています..."
	terraform plan

# init, plan, applyを順番に実行
deploy:
	@echo "デプロイを開始します..."
	@echo "===================="
	@make init
	@echo "===================="
	@make plan
	@echo "===================="
	@make apply
	@echo "デプロイが完了しました"

# リソースの削除（承認なし）
destroy:
	@echo "リソースを削除しています..."
	terraform destroy -auto-approve

# 確認付きでリソースを削除
destroy-confirm:
	@echo "リソースを削除します（確認あり）..."
	terraform destroy

# 変更の適用（承認なし）
apply:
	@echo "変更を適用しています..."
	terraform apply -auto-approve

# 確認付きで変更を適用
apply-confirm:
	@echo "変更を適用します（確認あり）..."
	terraform apply

# 構成ファイルのフォーマット
fmt:
	@echo "Terraformファイルをフォーマットしています..."
	terraform fmt

# 構成の検証
validate:
	@echo "構成を検証しています..."
	terraform validate

# 一時ファイルとキャッシュの削除
clean:
	@echo "一時ファイルを削除しています..."
	rm -rf .terraform
	rm -f terraform.tfstate.backup
	rm -f .terraform.lock.hcl

# すべてをクリーンな状態から実行
all: clean init validate plan apply

# ヘルプメッセージ
help:
	@echo "使用可能なコマンド:"
	@echo "  make init              - Terraformの初期化"
	@echo "  make plan              - 変更計画の表示"
	@echo "  make deploy            - init, plan, applyを順番に実行"
	@echo "  make destroy           - リソースの削除（承認なし）"
	@echo "  make destroy-confirm   - リソースの削除（確認あり）"
	@echo "  make apply             - 変更の適用（承認なし）"
	@echo "  make apply-confirm     - 変更の適用（確認あり）"
	@echo "  make fmt               - 構成ファイルのフォーマット"
	@echo "  make validate          - 構成の検証"
	@echo "  make clean             - 一時ファイルの削除"
	@echo "  make all               - クリーンな状態から初期化、検証、計画、適用まで実行"
	@echo "  make help              - このヘルプメッセージを表示"

# 環境変数の出力（デバッグ用）
env:
	@echo "AWS_REGION: $(AWS_REGION)"
	@terraform --version

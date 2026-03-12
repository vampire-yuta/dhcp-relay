.PHONY: help up down halt destroy ssh-client1 ssh-client2 ssh-client3 ssh-relay1 ssh-relay2 ssh-relay3 ssh-router ssh-dhcpserver status ps reload provision update

help: ## このヘルプメッセージを表示
	@echo "利用可能なコマンド:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

up: ## 全VMを起動（client1-3, relay1-3, router, dhcpserver）
	vagrant up

down: ## 全VMを停止
	vagrant halt

halt: ## 全VMを停止（downと同じ）
	vagrant halt

destroy: ## 全VMを削除
	@echo "警告: 仮想マシンを完全に削除します。よろしいですか？ [y/N]"
	@read -r confirm && [ "$$confirm" = "y" ] && vagrant destroy -f || echo "キャンセルしました"

ssh-client1: ## Client1 (56.0) に SSH
	vagrant ssh client1
ssh-client2: ## Client2 (57.0) に SSH
	vagrant ssh client2
ssh-client3: ## Client3 (58.0) に SSH
	vagrant ssh client3

ssh-relay1: ## Relay1 に SSH
	vagrant ssh relay1
ssh-relay2: ## Relay2 に SSH
	vagrant ssh relay2
ssh-relay3: ## Relay3 に SSH
	vagrant ssh relay3

ssh-router: ## Router に SSH
	vagrant ssh router

ssh-dhcpserver: ## DHCP Server に SSH
	vagrant ssh dhcpserver

status: ## VM の状態を確認
	vagrant status

ps: status ## VM の状態を確認（status のエイリアス）
	@vagrant status

reload: ## 全VMを再起動（設定変更を反映）
	vagrant reload

provision: ## プロビジョニングを再実行
	vagrant provision

update: ## box を最新版に更新
	vagrant box update

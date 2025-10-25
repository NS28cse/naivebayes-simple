# RStudio Serverがプリインストールされた公式イメージをベースにする
FROM docker.io/rocker/rstudio:4.4

# システムを更新し、Perlをインストールする
# - `sudo` は rocker イメージ内で root 権限を得るために必要
# - `-y` はインストールの確認を自動で「はい」にするオプション
RUN sudo apt-get update && \
    sudo apt-get install -y perl && \
    sudo rm -rf /var/lib/apt/lists/*

# (オプション) データ操作に便利な tidyverse パッケージをインストール
# RUN install2.r --error --deps TRUE tidyverse

# コンテナ内の作業ディレクトリを設定
WORKDIR /home/rstudio/project

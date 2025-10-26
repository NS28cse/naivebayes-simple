# naivebayes-simple

PerlとRによるナイーブベイズ分類器の実装．
ベルヌーイモデルと多項モデルのそれぞれMLE, MAPをサポートします．
使用する学習データも標的データもスペース（半角/全角）区切りのテキストファイルで，分類済みであることを前提とし精度を算出します．

## 動作環境

`.devcontainer/Dockerfile`にコンテナ環境を定義しています．
必要なものを実機にインストールして実行しても構いません．
主に以下の３つです．
* R
* R パッケージ: `data.table`
* Perl

コンテナを使う場合，コンテナを起動しコンテナ内のRstudio serverにブラウザから接続してRstudioを使うことができます．
やり方は調べればわかるので省略．

## ファイル配置

`data/` 配下に，以下の構造でデータを配置します．

* **訓練データ**: `data/learnU/<クラス名>/<文書ファイル>.txt`
* **評価データ**: `data/correctU/<クラス名>/<文書ファイル>.txt`

## 設定

`src/config.R` で，訓練するモデルの種類 (`active_models`) や，入出力パス (`paths`) を変更できます．

## 実行

Rの作業ディレクトリをプロジェクトルートに設定して実行します．

1.  **学習**:
    ```R
    source('src/main_train.R')
    ```
    * モデルは `output/model_nb_trained.RData` に保存されます．

2.  **分類**:
    ```R
    source('src/main_classify.R')
    ```

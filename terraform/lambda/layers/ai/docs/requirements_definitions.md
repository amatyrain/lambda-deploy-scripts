### 要件
* terraformを使ってlambda layerはデプロイします
    * デプロイはdeploy.sh一発で行えるようにしてください
* 出力されるlayer.zipは以下の構成を想定しています
```
layer.zip
└── python/
    └── ライブラリファイル群
```
* lambdaとバイナリ環境を合わせるために適切なdockerイメージのコンテナ内でライブラリをインストールするのがよいでしょう
* インストールするライブラリはrequirements/prod.txtに記載しています

* 最終的に出力されたlayer.zipが想定通りの構成になっていることを確認したのち、対応完了としてください
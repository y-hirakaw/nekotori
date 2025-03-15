import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    // ゲーム関連のプロパティ
    private var lastUpdateTime: TimeInterval = 0
    private var enemyAI: EnemyAI!
    private var selectedCatType: CatType = .normal
    private var foodLabel: SKLabelNode!
    private var tileSize: CGSize = CGSize(width: 50, height: 50)
    
    // スワイプ操作検出用のプロパティ
    private var startTouchPosition: CGPoint?
    private var selectedCat: CatNode?
    
    // 猫タイプセレクターボタン
    private var catTypeButtons: [CatType: SKNode] = [:]
    
    override func didMove(to view: SKView) {
        // ゲームマネージャーをリセット
        GameManager.shared.resetGame()
        
        // 背景色設定
        backgroundColor = SKColor.darkGray
        
        // フィールドをセットアップ
        setupField()
        
        // UIをセットアップ
        setupUI()
        
        // 敵AIをセットアップ
        enemyAI = EnemyAI(difficulty: .normal, gameScene: self)
    }
    
    /// フィールドのセットアップ
    private func setupField() {
        self.anchorPoint = CGPoint(x: 0, y: 0)
        let gridWidth = 8
        let gridHeight = 12
        
        // スクリーンサイズに応じてタイルサイズを調整（上下のUIスペースを考慮）
        let verticalUISpace = size.height * 0.2 // 画面の20%をUI用に確保
        let maxTileWidth = size.width / CGFloat(gridWidth)
        let maxTileHeight = (size.height - verticalUISpace) / CGFloat(gridHeight)
        let tileLength = min(maxTileWidth, maxTileHeight)
        tileSize = CGSize(width: tileLength, height: tileLength)
        
        // フィールド全体の大きさを計算
        let fieldWidth = tileSize.width * CGFloat(gridWidth)
        let fieldHeight = tileSize.height * CGFloat(gridHeight)
        
        // フィールドの開始位置を計算
        // 水平方向は中央
        let startX = (size.width - fieldWidth) / 2
        // 垂直方向は、上部UI用のスペースを確保して配置
        let topUISpace = size.height * 0.12 // 画面上部12%をUI用に
        let startY = ((size.height - topUISpace) - fieldHeight) / 2
        
        // タイルを配置
        for y in 0..<gridHeight {
            for x in 0..<gridWidth {
                let tilePosition = CGPoint(
                    x: startX + CGFloat(x) * tileSize.width + tileSize.width / 2,
                    y: startY + CGFloat(y) * tileSize.height + tileSize.height / 2
                )
                
                let tile = TileNode(gridPosition: (x: x, y: y), size: tileSize)
                tile.position = tilePosition
                
                // 特定のタイルを初期プレイヤー領域または敵領域に設定
                if y < 2 {
                    // 下部2行はプレイヤーの初期領域
                    tile.progressCapture(amount: 1.0, newOwner: .player)
                } else if y >= gridHeight - 2 {
                    // 上部2行は敵の初期領域
                    tile.progressCapture(amount: 1.0, newOwner: .enemy)
                }
                
                addChild(tile)
                GameManager.shared.addTileToGrid(tile: tile)
            }
        }
    }
    
    /// UIをセットアップ
    private func setupUI() {
        // 餌の量を表示するラベル
        foodLabel = SKLabelNode(text: "餌: \(GameManager.shared.foodAmount)")
        foodLabel.fontColor = SKColor.white
        foodLabel.fontSize = 24
        foodLabel.position = CGPoint(x: size.width * 0.1, y: size.height * 0.95)
        addChild(foodLabel)
        
        // 猫タイプセレクターの位置を計算（下部に配置）
        let selectorY = size.height * 0.08
        let buttonSpacing = size.width * 0.2
        let startX = (size.width - buttonSpacing * CGFloat(CatType.allCases.count - 1)) / 2
        
        // 猫タイプセレクターを作成
        for (index, catType) in CatType.allCases.enumerated() {
            let button = createCatTypeButton(for: catType)
            let xPos = startX + CGFloat(index) * buttonSpacing
            button.position = CGPoint(x: xPos, y: selectorY)
            catTypeButtons[catType] = button
            addChild(button)
        }
        
        // 最初に通常猫を選択状態に
        updateSelectedCatTypeDisplay()
    }
    
    /// 猫タイプ選択ボタンを作成
    private func createCatTypeButton(for catType: CatType) -> SKNode {
        let container = SKNode()
        
        // ボタンの背景
        let background = SKShapeNode(circleOfRadius: 35)
        background.fillColor = .gray
        background.strokeColor = .lightGray
        background.name = "button_\(catType.rawValue)"
        container.addChild(background)
        
        // 猫タイプの表示
        let label = SKLabelNode(text: catType.displayName.prefix(1).uppercased())
        label.fontSize = 24
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        container.addChild(label)
        
        // コスト表示
        let costLabel = SKLabelNode(text: "\(catType.summonCost)")
        costLabel.fontSize = 18
        costLabel.fontColor = .yellow
        costLabel.position = CGPoint(x: 0, y: -45)
        container.addChild(costLabel)
        
        return container
    }
    
    /// 選択中の猫タイプ表示を更新
    private func updateSelectedCatTypeDisplay() {
        for (type, button) in catTypeButtons {
            if let background = button.childNode(withName: "button_\(type.rawValue)") as? SKShapeNode {
                background.fillColor = type == selectedCatType ? .blue : .gray
            }
        }
    }
    
    /// 餌表示の更新
    private func updateFoodDisplay() {
        foodLabel.text = "餌: \(GameManager.shared.foodAmount)"
    }
    
    /// タップした位置のタイルを取得
    private func getTileAt(position: CGPoint) -> TileNode? {
        let nodes = nodes(at: position)
        for node in nodes {
            if let tile = node as? TileNode {
                return tile
            }
        }
        return nil
    }
    
    /// タップした位置の猫を取得
    private func getCatAt(position: CGPoint) -> CatNode? {
        let nodes = nodes(at: position)
        for node in nodes {
            if let cat = node as? CatNode, cat.owner == .player {
                return cat
            }
        }
        return nil
    }
    
    /// 猫タイプ選択ボタンがタップされたかチェック
    private func checkCatTypeButtonTapped(at position: CGPoint) -> Bool {
        for (type, button) in catTypeButtons {
            if button.contains(position) {
                selectedCatType = type
                updateSelectedCatTypeDisplay()
                return true
            }
        }
        return false
    }
    
    /// 猫の召喚処理
    private func summonCat(at position: CGPoint) {
        guard let tile = getTileAt(position: position) else { return }
        
        // タイルがプレイヤーの領域かチェック
        if tile.owner == .player {
            // 猫を召喚
            if let cat = GameManager.shared.summonCat(
                catType: selectedCatType,
                position: tile.position,
                owner: .player,
                size: CGSize(width: 30, height: 30)
            ) {
                addChild(cat)
                
                // 餌表示を更新
                updateFoodDisplay()
            }
        }
    }
    
    // タッチ開始
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // 猫タイプボタンがタップされた場合
        if checkCatTypeButtonTapped(at: location) {
            return
        }
        
        // タッチ開始位置を記録
        startTouchPosition = location
        
        // プレイヤーの猫が選択されたかチェック
        selectedCat = getCatAt(position: location)
    }
    
    // タッチ移動（スワイプ）
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 選択中の猫がない場合は何もしない
        guard let selectedCat = selectedCat else { return }
        guard let touch = touches.first else { return }
        
        let location = touch.location(in: self)
        guard let startPos = startTouchPosition else { return }
        
        // スワイプの長さを計算
        let dx = location.x - startPos.x
        let dy = location.y - startPos.y
        let distance = sqrt(dx*dx + dy*dy)
        
        // スワイプが十分な長さの場合
        if distance > 30 {
            // スワイプの方向によって猫の行動を変更
            if abs(dx) > abs(dy) {
                // 水平方向のスワイプ
                selectedCat.toggleMode()
            } else {
                // 垂直方向のスワイプ
                // タップ位置のタイルを取得
                if let targetTile = getTileAt(position: location) {
                    selectedCat.moveToTile(targetTile)
                }
            }
            
            // 選択をリセット
            self.selectedCat = nil
            startTouchPosition = nil
        }
    }
    
    // タッチ終了
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let startPos = startTouchPosition else { return }
        
        let location = touch.location(in: self)
        let dx = location.x - startPos.x
        let dy = location.y - startPos.y
        let distance = sqrt(dx*dx + dy*dy)
        
        // タップ（スワイプでない場合）
        if distance < 10 {
            // 猫が選択されていなければ、タップ位置に猫を召喚
            if selectedCat == nil {
                summonCat(at: location)
            }
        }
        
        // 状態をリセット
        selectedCat = nil
        startTouchPosition = nil
    }
    
    // タッチキャンセル
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        selectedCat = nil
        startTouchPosition = nil
    }
    
    // 毎フレーム更新処理
    override func update(_ currentTime: TimeInterval) {
        // 初回の更新
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }
        
        // 経過時間を計算
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // ゲームマネージャーの更新
        GameManager.shared.update(deltaTime: deltaTime)
        
        // 敵AIの更新
        enemyAI.update(deltaTime: deltaTime)
        
        // 猫の更新処理
        for cat in GameManager.shared.playerCats + GameManager.shared.enemyCats {
            cat.update(deltaTime: deltaTime)
        }
        
        // 餌の表示を更新
        updateFoodDisplay()
        
        // 餌増加速度の更新
        GameManager.shared.updateFoodIncreaseRate()
    }
}

import Foundation
import SpriteKit

/// ゲームの状態管理を行うクラス
class GameManager {
    /// シングルトンインスタンス
    static let shared = GameManager()
    
    /// 現在の餌の量
    private(set) var foodAmount: Int = 30
    
    /// 餌の増加速度（1秒間に増える量）
    private(set) var foodIncreaseRate: Double = 1.0
    
    /// プレイヤーの猫リスト
    private(set) var playerCats: [CatNode] = []
    
    /// 敵の猫リスト
    private(set) var enemyCats: [CatNode] = []
    
    /// フィールドのグリッド（タイルの二次元配列）
    private(set) var grid: [[TileNode]] = []
    
    /// ゲームオーバー状態かどうか
    private(set) var isGameOver: Bool = false
    
    /// プレイヤーの勝利かどうか
    private(set) var isPlayerWin: Bool = false
    
    private init() {}
    
    /// ゲームの状態をリセットする
    func resetGame() {
        foodAmount = 30
        foodIncreaseRate = 1.0
        playerCats = []
        enemyCats = []
        grid = []
        isGameOver = false
        isPlayerWin = false
    }
    
    /// 餌を追加する
    /// - Parameter amount: 追加する量
    func addFood(amount: Int) {
        foodAmount += amount
    }
    
    /// 餌を消費する
    /// - Parameter amount: 消費する量
    /// - Returns: 消費に成功したかどうか
    func consumeFood(amount: Int) -> Bool {
        guard foodAmount >= amount else {
            return false
        }
        
        foodAmount -= amount
        return true
    }
    
    /// 餌の増加速度を更新する
    func updateFoodIncreaseRate() {
        var playerTilesCount = 0
        
        // プレイヤーが所有しているタイル数をカウント
        for row in grid {
            for tile in row {
                if tile.owner == .player {
                    playerTilesCount += 1
                }
            }
        }
        
        // 基本の増加速度 + 所有タイル数に応じたボーナス
        foodIncreaseRate = 1.0 + Double(playerTilesCount) * 0.2
    }
    
    /// 猫を召喚する
    /// - Parameters:
    ///   - catType: 召喚する猫のタイプ
    ///   - position: 召喚する位置
    ///   - owner: 召喚する所有者
    ///   - size: 猫のサイズ
    /// - Returns: 召喚された猫のノード（召喚に失敗した場合はnil）
    func summonCat(catType: CatType, position: CGPoint, owner: TileNode.Owner, size: CGSize) -> CatNode? {
        // プレイヤーの場合は餌を消費する
        if owner == .player {
            let cost = catType.summonCost
            guard consumeFood(amount: cost) else {
                return nil
            }
        }
        
        // 新しい猫を作成
        let cat = CatNode(catType: catType, owner: owner, size: size)
        cat.position = position
        
        // リストに追加
        if owner == .player {
            playerCats.append(cat)
        } else if owner == .enemy {
            enemyCats.append(cat)
        }
        
        return cat
    }
    
    /// タイルをグリッドに追加する
    /// - Parameter tile: 追加するタイル
    func addTileToGrid(tile: TileNode) {
        let x = tile.gridPosition.x
        let y = tile.gridPosition.y
        
        // 必要に応じてグリッドを拡張
        while grid.count <= y {
            grid.append([])
        }
        
        while grid[y].count <= x {
            grid[y].append(contentsOf: Array(repeating: TileNode(gridPosition: (x: grid[y].count, y: y), size: tile.size), count: x + 1 - grid[y].count))
        }
        
        // タイルを配置
        grid[y][x] = tile
    }
    
    /// プレイヤーが勝利する条件をチェック
    /// - Returns: プレイヤーの勝利かどうか
    func checkPlayerWinCondition() -> Bool {
        var playerTiles = 0
        var enemyTiles = 0
        var totalTiles = 0
        
        for row in grid {
            for tile in row {
                totalTiles += 1
                
                if tile.owner == .player {
                    playerTiles += 1
                } else if tile.owner == .enemy {
                    enemyTiles += 1
                }
            }
        }
        
        // プレイヤーが7割以上のタイルを所有していたら勝利
        return Double(playerTiles) / Double(totalTiles) >= 0.7
    }
    
    /// 敵が勝利する条件をチェック
    /// - Returns: 敵の勝利かどうか
    func checkEnemyWinCondition() -> Bool {
        var playerTiles = 0
        var enemyTiles = 0
        var totalTiles = 0
        
        for row in grid {
            for tile in row {
                totalTiles += 1
                
                if tile.owner == .player {
                    playerTiles += 1
                } else if tile.owner == .enemy {
                    enemyTiles += 1
                }
            }
        }
        
        // 敵が7割以上のタイルを所有していたら敵の勝利
        return Double(enemyTiles) / Double(totalTiles) >= 0.7
    }
    
    /// ゲームの更新処理
    /// - Parameter deltaTime: 経過時間
    func update(deltaTime: TimeInterval) {
        // 餌の自動増加
        foodAmount += Int(foodIncreaseRate * deltaTime)
        
        // 勝利条件チェック
        if checkPlayerWinCondition() {
            isGameOver = true
            isPlayerWin = true
        } else if checkEnemyWinCondition() {
            isGameOver = true
            isPlayerWin = false
        }
    }
}
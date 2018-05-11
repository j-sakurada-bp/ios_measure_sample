import Foundation
import UIKit

///
class LogWriter {
    
    // APIKEY
    let APIKEY = "TZyScwVfCb7tYEoGmTzKo46CM0FHv87N778QR8Qa"
    // WebサービスAPI
    let SERVER_URL = "https://5wudskjzg7.execute-api.ap-northeast-1.amazonaws.com/prod/register_device_measurement"
    
    // 日付フォーマット
    let _COMMON_DATE_FORMAT = "yyyyMMddHHmmssSSS"
    // キュー並行実行多重度（並行実行一切なし）
    let _CONCURRENT_COUNT = 1
    // ログファイル格納ディレクトリ
    let _dirpath: URL?
    // デバイスID
    let _uuid: String
    
    // サーバリクエストインターバル
    let _request_intarval: Double
    // ログ出力管理用キュー
    let _queue: OperationQueue
    let _requestQueue = OperationQueue()
    // サーバ通信タスク管理用タイマー
    var _timer: Timer?
    
    //MARK: - イニシャライザ
    
    /// イニシャライザ
    init(queue: OperationQueue, requestIntarval: Double = 1) {
        
        _queue = queue
        _request_intarval = requestIntarval
        _uuid = UIDevice.current.identifierForVendor!.uuidString
        _dirpath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        initLogFile()
    }
    
    // ============================================================
    //MARK: - internal func
    
    /// ログファイルを初期化する。
    internal func initLogFile() {
        createFile(type: DATA_TYPE.ACCELARATE)
        createFile(type: DATA_TYPE.GYRO)
        createFile(type: DATA_TYPE.MAGNETO)
        createFile(type: DATA_TYPE.GRAVITY)
        createFile(type: DATA_TYPE.GPS)
    }
    
    /// 既に存在するファイルの末尾に文字列を追加する。
    ///
    /// - Parameters:
    ///   - type: データ種別
    ///   - data: 実データ
    internal func appendLog(type: DATA_TYPE, data: [Double]) {
        
        // 浮動小数点数の配列を文字列配列へ変換
        var ary = data.map { String($0) }
        // 時刻情報を追加
        let date = getDateString()
        ary.insert("\(date)", at: 0)
        // 文字列に変換
        let data = ary.joined(separator: ",")
        
        appendText(type: type, data: data)
    }
    
    /// サーバへのリクエストのポーリング処理を開始する。
    internal func startOperationSendRequest() {
        
        // キューの多重度を設定（並行実行を抑止する）
        _queue.maxConcurrentOperationCount = _CONCURRENT_COUNT
        // 既定インターバルでサーバリクエスト処理を実行する
        _timer = Timer.scheduledTimer(
            timeInterval: _request_intarval,
            target: self,
            selector: #selector(LogWriter.sendRequest),
            userInfo: nil,
            repeats: true)
    }
    
    /// リクエスト送信ポーリングを終了する。
    internal func stopOperationSendRequest() {
        _timer?.invalidate()
    }
    
    // ============================================================
    //MARK: - private func
    
    /// タイマーからコールバックされる関数。
    /// リクエスト送信関数に処理を委譲。
    @objc private func sendRequest() {
        _queue.addOperation(self.sendRequestForPersistetLog)
    }
    
    /// サーバにログ記録リクエストを送信する。
    /// 1. テキストファイルに蓄積されたログ情報を取得。
    /// 2. サーバにリクエストを送信。
    /// 3. ログファイルを初期化。
    private func sendRequestForPersistetLog() {
        
        print("************************************************************ \(Date())") // TODO 削除
        
        // 各ログリストから、サーバコールパラメータを生成する。
        let param = createLogParameter()
        // 各ログリストをクリアする
        self.initLogFile()
        print("======== ログファイルがクリアされました ========") // TODO 削除
        print() // TODO 削除
        
        _requestQueue.addOperation { () -> Void in
            // ダミーサーバ通信
            // (通信のレスポンスを同期化して、何か処理を行うと言うことは)
            self.post(url: self.SERVER_URL,
                 data: param,
                 onsuccess: { (res, data) in
                    print("======== リクエスト送信 -> レスポンス正常終了 ========") // TODO 削除
                    let json = self.dataToJson(data: data) // TODO 削除
                    print("RES: \(res), DATA: \(json)") // TODO 削除
                },
                 onerror: { (res, error) in
                    print("======== リクエスト送信 -> レスポンス通信中にエラー発生 ========")
                    print("\(res), \(error)")
                }
            )
        }
    }
    
    /// ダミーサーバ通信処理
    ///
    /// - Parameters:
    ///   - url: サーバURL
    ///   - data: パラメータ文字列
    ///   - onsuccess: サーバ通信成功時処理関数
    ///   - onerror: サーバ通信失敗時処理関数
    private func post(url: String,
                      data: String,
                      onsuccess: @escaping (_ res: URLResponse, _ data: Data?) -> Void,
                      onerror: @escaping (_ res: URLResponse, _ error: Error) -> Void) {
        
        var req = URLRequest(url: URL(string: url)!)
        req.httpMethod = "POST"
        req.timeoutInterval = 60
        req.httpBody = data.data(using: String.Encoding.utf8)
        req.addValue(APIKEY, forHTTPHeaderField: "x-api-key")
        
        URLSession.shared.dataTask(with: req) { (data, res, err) in
            if err != nil {
                onerror(res!, err!)
            } else {
                onsuccess(res!, data)
            }
        }.resume()
    }
    
    ///
    ///
    /// - Parameter data:
    /// - Returns:
    private func dataToJson(data: Data?) -> Any {
        return try! JSONSerialization.jsonObject(
            with: data!,
            options: JSONSerialization.ReadingOptions.allowFragments)
    }
    
    /// ログファイルからログ情報を取得し、サーバ送信用パラメータ文字列を生成する。
    ///
    /// - Returns: サーバ送信用パラメータ文字列
    private func createLogParameter() -> String {
        
        // 各ログファイルからログリストを取得
        let accLog = getLogStringFor(DATA_TYPE.ACCELARATE)
        let gyrLog = getLogStringFor(DATA_TYPE.GYRO)
        let mgtLog = getLogStringFor(DATA_TYPE.MAGNETO)
        let grvLog = getLogStringFor(DATA_TYPE.GRAVITY)
        let gpsLog = getLogStringFor(DATA_TYPE.GPS)

        // ファイル生成日時
        let datetime = getDateString()
        // JSON文字列を生成
        return "{\"uuid\":\"\(_uuid)\",\"datetime\":\"\(datetime)\",\(accLog),\(gyrLog),\(mgtLog),\(grvLog),\(gpsLog)}"
    }
    
    /// 指定されたログ種別のログ情報をログファイルから取得し、サーバ送信用文字列を生成する。
    ///
    /// - Parameter type: ログ種別
    /// - Returns: サーバ送信用文字列
    private func getLogStringFor(_ type: DATA_TYPE) -> String {
        
        let typeName = type.rawValue
        let logs = readTextToLines(type: type) // 「""」行（空行）を振るい落としている
        let log = "\"" + logs.joined(separator: "\",\n\"") + "\""
        // JOSN文字列を生成
        return "\"\(typeName)\":[\(log)]";
    }
    
    /// 指定されたログ種別のログ情報（文字列）を、改行文字で行配列に変換して取得する。
    ///
    /// - Parameter type: <#type description#>
    /// - Returns: <#return value description#>
    private func readTextToLines(type: DATA_TYPE) -> [String] {
        guard let log = readText(type: type) else {
            return [];
        }
        return log.split(separator: "\n").map{ String($0) }
    }
    
    /// 指定されたログ種別のログ情報をテキストファイルから取得する。
    ///
    /// - Parameter type: <#type description#>
    /// - Returns: <#return value description#>
    private func readText(type: DATA_TYPE) -> String? {
        // ファイル読み出し
        if let url = getFileUrl(type: type), let readtext = readTextFile(url: url) {
            return readtext
        }
        
        print("ERROR raised on readText. maybe url is isvalid or file does not exist.")
        return nil
    }
    
    /// ファイルからテキストを読み出す。
    ///
    /// - Parameter url:
    /// - Returns:
    private func readTextFile(url: URL) -> String? {
        do {
            let text = try String(contentsOf: url, encoding: String.Encoding.utf8)
            return text
        } catch let error as NSError {
            print("failed to read: \(error)")
            return nil
        }
    }
    
    /// 指定されたファイルを生成する。
    ///
    /// - Parameters:
    ///   - filename:
    ///   - data:
    private func createFile(type: DATA_TYPE) {
        if let path = getFileUrl(type: type) {
            do {
                try "".write(to: path, atomically: true, encoding: String.Encoding.utf8)
            } catch let error as NSError {
                print("failed to write: \(error)")
            }
        }
    }
    
    /// Date型を文字列に変換する。
    /// 書式は定数で指定している。
    ///
    /// - Returns:
    private func getDateString() -> String {
        let format = DateFormatter()
        format.dateFormat = _COMMON_DATE_FORMAT
        return format.string(from: Date())
    }
    
    /// 既存のファイルの末尾に指定の文字列を追加する。
    ///
    /// - Parameters:
    ///   - filepath:
    ///   - data:
    private func appendText(type: DATA_TYPE, data: String) {
        
        do {
            let file = getFileUrl(type: type);
            let fh = try FileHandle(forWritingTo: file!)
            defer {
                fh.closeFile()
            }
            
            let append = data + "\n"
            fh.seekToEndOfFile()
            fh.write(append.data(using: String.Encoding.utf8)!)
            
        } catch let error as NSError {
            print("failed to append: \(error)")
        }
    }
    
    /// ファイルへの絶対パスを取得する。
    ///
    /// - Returns:
    private func getFileUrl(type: DATA_TYPE) -> URL? {
        let filename = resolveFileName(type: type)
        return _dirpath!.appendingPathComponent(filename) // パスは必ず取得できるはずなので"!"
    }
}

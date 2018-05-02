import UIKit
import CoreMotion
import CoreLocation

class ViewController: UIViewController {

    // == (計測系)ここから - インスタンス変数宣言箇所に記述する ==========================================================
    // GPS計測マネージャ
    let _locManager = CLLocationManager()
    // 加速度、ジャイロ、磁気計測マネージャ
    var _motionManager: MotionManager!
    // ログライター
    var _logWriter: LogWriter!
    // タスク管理キュー
    let _queue = OperationQueue()
    // GPS計測単位(距離)
    var _dist_filter: Double!
    // GPS計測精度
    var _loc_accuracy: CLLocationAccuracy!
    // == (計測系)ここまで ==========================================================

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // == (計測系)ここから - 初期化を行う箇所に記述する ==========================================================
        // [TODO] DBから初期化に必要なパラメータを取得して設定する
        let requestInterval: Double = 60
        let acc_interval: Double = 0.05
        let gyr_interval: Double = 0.05
        let mgt_interval: Double = 0.05
        // GPS計測用パラメータ
        _dist_filter = 10.0
        _loc_accuracy = kCLLocationAccuracyBest
        // [TODO] ここまで
        
        // 計測に必要なオブジェクトのイニシャライズ
        _queue.maxConcurrentOperationCount = 1
        _logWriter = LogWriter(queue: _queue, requestIntarval: requestInterval)
        _motionManager = MotionManager(queue: _queue,
                                       accIntarval: acc_interval,
                                       gyrIntarval: gyr_interval,
                                       mgtIntarval: mgt_interval)
        // == (計測系)ここまで ==========================================================
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func btnInitLogTapped(_ sender: UIButton) {
        _logWriter.initLogFile() // 端末上のログファイル(テキストファイル)をクリアする場合に使用する
    }
    
    @IBAction func btnStartTapped(_ sender: UIButton) {
        // == (計測系)ここから - 計測を開始する箇所に記述する ==========================================================
        startMeasure()
        // == (計測系)ここまで ==========================================================
    }
    
    @IBAction func btnFinishTapped(_ sender: UIButton) {
        // == (計測系)ここから - 計測を終了する箇所に記述する ==========================================================
        stopMeasure()
        // == (計測系)ここまで ==========================================================
    }
    
    // == (計測系)ここから ==========================================================
    //MARK: - センサー系
    
    func startMeasure() {
        // 加速度、ジャイロ、磁気の計測を開始
        _motionManager.startMeasurement()
        // GPSの計測を開始
        startMeasureLocation()
        // サーバへのリクエストのポーリング処理を開始
        _logWriter.startOperationSendRequest()
    }
    
    func stopMeasure() {
        // モーション系センサー停止
        _motionManager.stopMeasurement()
        // ロケーションセンサー停止
        _locManager.stopUpdatingHeading() // 電子コンパスの使用を終了する
        _locManager.stopUpdatingLocation() // GPSの使用を終了する
        // リクエストポーリング停止
        _logWriter.stopOperationSendRequest()
    }
    
    func startMeasureLocation() {
        setupLocManager()
        _locManager.startUpdatingHeading() // 電子コンパスの使用を開始する
        _locManager.startUpdatingLocation() // GPSの使用を開始する
    }
    
    /// ロケーションマネージャをセットアップする
    func setupLocManager() {
        
        _locManager.desiredAccuracy = _loc_accuracy // 最高精度
        _locManager.distanceFilter = _dist_filter // 10m毎に記録する
        _locManager.headingFilter = kCLHeadingFilterNone
        _locManager.headingOrientation = .portrait
        _locManager.delegate = self
        
        _locManager.requestWhenInUseAuthorization() // 端末上で「アクセス許可確認ダイアログ」が表示される
    }
    // == (計測系)ここまで ==========================================================
}

// == (計測系)ここから ==========================================================

// MARK: - CLLocationManagerDelegate適合

extension ViewController : CLLocationManagerDelegate { // View名は要修正
    
    /// ロケーションマネージャからのコールバック関数（成功時）
    ///
    /// - Parameters:
    ///   - manager:
    ///   - newLoc:
    ///   - notUsed:
    func locationManager(manager: CLLocationManager,
                         didUpdateToLocation newLoc: CLLocation,
                         fromLocation notUsed: CLLocation) {
        
        // GPS計測情報を保存するタスクをキューにappend
        _queue.addOperation({ () -> Void in
            let ary:[Double] = [
                newLoc.coordinate.longitude.binade, // 経度
                newLoc.coordinate.latitude.binade, // 緯度
                newLoc.altitude.binade, // 高度
                newLoc.speed.binade, // スピード
                newLoc.course.binade // 方角
            ]
            self._logWriter.appendLog(type: DATA_TYPE.GPS, data: ary)
        })
    }
    
    /// ロケーションマネージャからのコールバック関数（失敗 時）
    ///
    /// - Parameters:
    ///   - manager:
    ///   - error:
    private func locationManager(manager: CLLocation, didFailWithError error: Error) {
        // エラー発生時は無視する
        print("EROOR : \(error)")
    }
}
// == (計測系)ここまで ==========================================================

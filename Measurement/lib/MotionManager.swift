import Foundation
import UIKit
import CoreMotion
import CoreLocation

///
class MotionManager {
    
    // 計測マネージャ
    let _motManager: CMMotionManager
    // タスク管理キュー
    let _queue: OperationQueue
    // ログライター
    let _logWriter: LogWriter
    
    //MARK: - イニシャライザ
    
    /// イニシャライザ
    init(queue: OperationQueue,
         accIntarval: Double = 0.05,
         gyrIntarval: Double = 0.05,
         mgtIntarval: Double = 0.05) {
        
        _queue = queue
        _logWriter = LogWriter(queue: _queue)
        _motManager = CMMotionManager()
        _motManager.accelerometerUpdateInterval = accIntarval
        _motManager.gyroUpdateInterval = gyrIntarval
        _motManager.magnetometerUpdateInterval = mgtIntarval
    }
    
    deinit {
        // 念のため
        _motManager.stopAccelerometerUpdates()
        _motManager.stopGyroUpdates()
        _motManager.stopMagnetometerUpdates()
    }
    
    //MARK: - internal func
    
    /// 計測を開始する。
    internal func startMeasurement() {
        // 加速度、ジャイロ、磁気の計測を開始
        startMeasureAccelarate()
        startMeasureGyro()
        startMeasureMagneto()
    }
    
    /// 計測を終了する。
    internal func stopMeasurement() {
        // モーション系センサー停止
        _motManager.stopAccelerometerUpdates()
        _motManager.stopGyroUpdates()
        _motManager.stopMagnetometerUpdates()
    }
    
    //MARK: - private func
    
    /// 加速度の計測を開始する。
    private func startMeasureAccelarate() {
        
        _motManager.startAccelerometerUpdates(to: _queue, withHandler: { (data, error) in
            guard let x = data?.acceleration.x,
                let y = data?.acceleration.y,
                let z = data?.acceleration.z else {
                    return
            }
            // ファイルに出力
            self._logWriter.appendLog(type: DATA_TYPE.ACCELARATE, data: [x, y, z])
        })
    }
    
    /// ジャイロの計測を開始する。
    private func startMeasureGyro() {
        
        _motManager.startGyroUpdates(to: _queue, withHandler: { (data, error) in
            guard let x = data?.rotationRate.x,
                let y = data?.rotationRate.y,
                let z = data?.rotationRate.z else {
                    return
            }
            // ファイルに出力
            self._logWriter.appendLog(type: DATA_TYPE.GYRO, data: [x, y, z])
        })
    }
    
    /// 磁気の計測を開始する。
    private func startMeasureMagneto() {
        
        _motManager.startMagnetometerUpdates(to: _queue, withHandler: { (data, error) in
            guard let x = data?.magneticField.x,
                let y = data?.magneticField.y,
                let z = data?.magneticField.z else {
                    return
            }
            // ファイルに出力
            self._logWriter.appendLog(type: DATA_TYPE.MAGNETO, data: [x, y, z])
        })
    }
}

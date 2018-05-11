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
    ///
    /// - Parameters:
    ///   - queue: センサー情報を記録するタスクを管理するキュー
    ///   - accInterval: 加速度を計測する間隔
    ///   - gyrInterval: ジャイロを計測する間隔
    ///   - mgtInterval: 磁気を計測する間隔
    ///   - grvInterval: 重力加速度を計測する間隔
    init(queue: OperationQueue,
         accInterval: Double = 0.05,
         gyrInterval: Double = 0.05,
         mgtInterval: Double = 0.05,
         grvInterval: Double = 0.05) {
        
        _queue = queue
        _logWriter = LogWriter(queue: _queue)
        _motManager = CMMotionManager()
        _motManager.accelerometerUpdateInterval = accInterval
        _motManager.gyroUpdateInterval = gyrInterval
        _motManager.magnetometerUpdateInterval = mgtInterval
        _motManager.deviceMotionUpdateInterval = grvInterval
    }
    
    deinit {
        // 念のため
        _motManager.stopAccelerometerUpdates()
        _motManager.stopGyroUpdates()
        _motManager.stopMagnetometerUpdates()
        _motManager.stopDeviceMotionUpdates()
    }
    
    //MARK: - internal func
    
    /// 計測を開始する。
    internal func startMeasurement() {
        // 加速度、ジャイロ、磁気、重力加速度の計測を開始
        startMeasureAccelarate()
        startMeasureGyro()
        startMeasureMagneto()
        startMeasureGravity()
    }
    
    /// 計測を終了する。
    internal func stopMeasurement() {
        // モーション系センサー停止
        _motManager.stopAccelerometerUpdates()
        _motManager.stopGyroUpdates()
        _motManager.stopMagnetometerUpdates()
        _motManager.stopDeviceMotionUpdates()
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
    
    /// 重力加速度の計測を開始する。
    private func startMeasureGravity() {
        
        _motManager.startDeviceMotionUpdates(to: _queue, withHandler: { (data, error) in
            guard let x = data?.gravity.x,
                let y = data?.gravity.y,
                let z = data?.gravity.z else {
                    return
            }
            // ファイルに出力
            self._logWriter.appendLog(type: DATA_TYPE.GRAVITY, data: [x, y, z])
        })
    }
}

import Foundation

/// 列挙型「データ種別」
///
/// - ACCELARATE: 加速度
/// - GYRO: ジャイロ
/// - MAGNETO: 磁気
/// - GPS: GPS
enum DATA_TYPE: String {
    case ACCELARATE = "ACC"
    case GYRO = "GYR"
    case MAGNETO = "MGT"
    case GPS = "GPS"
}

// 通常のconstで良い。
enum LOG_FILE: String {
    case ACCELARATE = "accelarate.log"
    case GYRO = "gyro.log"
    case MAGNETO = "magneto.log"
    case GPS = "gps.log"
}

/// ファイル名を取得する。
///
/// - Parameter type:
/// - Returns:
func resolveFileName(type: DATA_TYPE) -> String {
    if type == DATA_TYPE.ACCELARATE {
        return LOG_FILE.ACCELARATE.rawValue
    }
    if type == DATA_TYPE.GYRO {
        return LOG_FILE.GYRO.rawValue
    }
    if type == DATA_TYPE.MAGNETO {
        return LOG_FILE.MAGNETO.rawValue
    }
    if type == DATA_TYPE.GPS {
        return LOG_FILE.GPS.rawValue
    }
    return "" // ありえないパス。戻り値のOptional化しない
}


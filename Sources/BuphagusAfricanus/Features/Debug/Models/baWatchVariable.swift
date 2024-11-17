import Foundation


// 添加一个用于存储监视变量的结构体
struct baWatchVariable: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var value: String
    let type: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: baWatchVariable, rhs: baWatchVariable) -> Bool {
        lhs.id == rhs.id
    }
}

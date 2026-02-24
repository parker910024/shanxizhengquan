import Foundation

let jsonString = """
{
    "data": {
        "is_dzjy": "1",
        "is_xgsg": "1",
        "is_xxps": "1",
        "list_dzjy": [
            {
                "id": 1,
                "name": "新广益",
                "code": "301687",
                "fx_price": "0",
                "fx_rate": "0"
            }
        ],
        "list_ps": [
            {
                "name": "新广益",
                "sgcode": "301687"
            },
            {
                "name": "薇东光"
            }
        ],
        "list_sg": [
            {
                "name": "海圣医疗",
                "sgcode": "832445",
                "fx_price": "12.64"
            }
        ]
    }
}
"""

if let data = jsonString.data(using: .utf8),
   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
   let dataDict = dict["data"] as? [String: Any] {
    
    print("sg: \(dataDict["list_sg"] as? [[String: Any]] ?? [])")
    print("ps: \(dataDict["list_ps"] as? [[String: Any]] ?? [])")
    print("dzjy: \(dataDict["list_dzjy"] as? [[String: Any]] ?? [])")
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Data
import Shared
import WebKit

private let log = Logger.browserLogger

let popup = PaymentHandlerPopupView(imageView: UIImageView(image: #imageLiteral(resourceName: "browser_lock_popup")), title: Strings.paymentRequestTitle, message: "")

class PaymentRequestExtension: NSObject {
    fileprivate weak var tab: Tab?
    
    init(tab: Tab) {
        self.tab = tab
        popup.addButton(title: Strings.paymentRequestPay) { () -> PopupViewDismissType in
            return .flyDown
        }
        popup.addButton(title: Strings.paymentRequestCancel) { () -> PopupViewDismissType in
            return .flyDown
        }

    }
}

extension PaymentRequestExtension: TabContentScript {
    static func name() -> String {
        return "PaymentRequest"
    }
    
    func scriptMessageHandlerName() -> String? {
        return "PaymentRequest"
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if message.name == "PaymentRequest", let body = message.body as? NSDictionary {
            guard let name = body["name"] as? String, let supportedInstruments = body["supportedInstruments"] as? String, let details = body["details"] as? String else {
                return
            }
            if name == "payment-request-show" {
                do {
                    guard let detailsData = details.data(using: String.Encoding.utf8), let supportedInstrumentsData = supportedInstruments.data(using: String.Encoding.utf8) else {
                        log.error("Error parsing data")
                        return
                    }
                    let d = try JSONDecoder().decode(PaymentRequestDetailsHandler.self, from: detailsData)
                    
                    let si =  try JSONDecoder().decode([PaymentRequestSupportedInstrumentsHandler].self, from: supportedInstrumentsData)
                    
                    log.info("Success!")
                } catch DecodingError.dataCorrupted(let context) {
                    log.error(context)
                } catch DecodingError.keyNotFound(let key, let context) {
                    log.info(context.debugDescription)
                    log.info(context.codingPath)
                } catch DecodingError.valueNotFound(let value, let context) {
                    log.info(context.debugDescription)
                    log.info(context.codingPath)
                } catch DecodingError.typeMismatch(let type, let context) {
                    log.info(context.debugDescription)
                    log.info(context.codingPath)
                } catch {
                    log.info(error)
                }
                popup.showWithType(showType: .flyUp)
            }
        }
    }
}

extension Strings {
    public static let paymentRequestTitle = NSLocalizedString("paymentRequestTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Review your payment", comment: "Title for Brave Payments")
    public static let paymentRequestPay = NSLocalizedString("paymentRequestPay", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Pay", comment: "Pay button on Payment Request screen")
    public static let paymentRequestCancel = NSLocalizedString("paymentRequestCancel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Cancel", comment: "Canceel button on Payment Request screen")
}

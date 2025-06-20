//
//  DigitalLineItemTableViewCellViewModel.swift
//  
//
//  Created by David Vizaknai on 23.02.2023.
//

import GiniCaptureSDK
import UIKit

struct DigitalLineItemTableViewCellViewModel {

    var lineItem: DigitalInvoice.LineItem

    let indexPath: IndexPath
    let invoiceNumTotal: Int
    let invoiceLineItemsCount: Int
    let nameMaxCharactersCount: Int
    
    var index: Int {
        indexPath.row
    }

    private var quantityString: String {
        let string = NSLocalizedStringPreferredGiniBankFormat("ginibank.digitalinvoice.lineitem.quantity",
                                                              comment: "Quantity")
        return String.localizedStringWithFormat(string, lineItem.quantity)
    }

    var nameLabelString: String? {
        guard let name = lineItem.name else { return nil }
        return "\(quantityString) \(name)"
    }

    var totalPriceString: String? {
        return lineItem.totalPrice.string
    }

    var unitPriceString: String? {
        guard let priceString = lineItem.price.string else { return nil }
        let perUnitString = NSLocalizedStringPreferredGiniBankFormat("ginibank.digitalinvoice.lineitem.unitTitle",
                                                                     comment: "per unit")
        return "\(priceString) \(perUnitString)"
    }

    var modeSwitchTintColor: UIColor {
        switch lineItem.selectedState {
        case .selected:
            return .GiniBank.accent1
        case .deselected:
            return GiniColor(light: .GiniBank.light3, dark: .GiniBank.dark4).uiColor()
        }
    }
}

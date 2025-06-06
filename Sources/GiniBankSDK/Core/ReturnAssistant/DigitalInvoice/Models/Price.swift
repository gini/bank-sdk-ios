//
//  Price.swift
// GiniBank
//
//  Created by Maciej Trybilo on 11.12.19.
//

import Foundation

struct Price {

    let value: Decimal
    let currencyCode: String

    init(value: Decimal, currencyCode: String) {
        self.value = value
        self.currencyCode = currencyCode
    }

    init?(extractionString: String) {

        let components = extractionString.components(separatedBy: ":")

        guard components.count == 2 else { return nil }

        guard let decimal = Decimal(string: components.first ?? "", locale: Locale(identifier: "en")),
            let currencyCode = components.last?.lowercased() else {
                return nil
        }

        self.value = decimal
        self.currencyCode = currencyCode
    }

    var extractionString: String {
        let formatter = NumberFormatter.twoDecimalPriceFormatter
        formatter.usesGroupingSeparator = false
        formatter.decimalSeparator = "."
        guard let formattedString = formatter.string(from: NSDecimalNumber(decimal: value)) else { return "" }
        return "\(formattedString):\(currencyCode.uppercased())"
    }

    var currencySymbol: String? {
        return (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.currencySymbol,
                                                        value: currencyCode)
    }

    var string: String? {
        var sign = ""
        if value < 0 {
            sign = "- "
        }

        let result = sign + (currencySymbol ?? "") + (Price.stringWithoutSymbol(from: abs(value)) ?? "")

        if result.isEmpty { return nil }

        return result
    }

    var stringWithoutSymbol: String? {
        return Price.stringWithoutSymbol(from: value)
    }

    var localizedStringWithoutCurrencyCode: String? {
        return Price.localizedStringWithoutCurrencyCode(from: value)
    }

    var localizedStringWithCurrencyCode: String? {
        let formatter = NumberFormatter.twoDecimalPriceFormatter
        guard let formattedValue = formatter.string(from: NSDecimalNumber(decimal: value)) else { return nil }
        return "\(formattedValue) \(currencyCode.uppercased())"
    }

    static func stringWithoutSymbol(from value: Decimal) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = ""
        return formatter.string(from: NSDecimalNumber(decimal: value))?.trimmingCharacters(in: .whitespaces)
    }

    static func formatAmountString(newText: String) -> String? {
        let onlyDigits = String(newText.trimmingCharacters(in: .whitespaces)
            .filter { c in c != "," && c != "."}
            .prefix(7)
        )
        if let decimal = Decimal(string: onlyDigits) {
            let decimalWithFraction = decimal / 100
            return Price.stringWithoutSymbol(from: decimalWithFraction)?.trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    static func convertLocalizedStringToDecimal(_ priceString: String) -> Decimal? {
        let trimmedString = priceString.trimmingCharacters(in: .whitespaces)
        guard let number = NumberFormatter.twoDecimalPriceFormatter.number(from: trimmedString) else {
            return nil
        }
        return roundToTwoDecimalPlaces(number.decimalValue)
    }

    /**
     Rounds a Decimal value to two decimal places using "bankers' rounding" (round half to even).
     
     - Parameter value: The Decimal value to be rounded.
     - Returns: The rounded Decimal value to two decimal places.
     
     ### How Bankers' Rounding Works:
     Bankers' rounding minimizes rounding bias by rounding to the nearest even number when the value is exactly halfway between two possible outcomes.
     
     ### Examples:
     ```swift
     // Rounding away from halfway points:
     let rounded1 = roundToTwoDecimalPlaces(1.234) // Output: 1.23 (less than halfway, rounds down)
     let rounded2 = roundToTwoDecimalPlaces(1.236) // Output: 1.24 (greater than halfway, rounds up)
     
     // Rounding exactly halfway:
     let rounded3 = roundToTwoDecimalPlaces(1.245) // Output: 1.24 (halfway, rounds to even)
     let rounded4 = roundToTwoDecimalPlaces(1.255) // Output: 1.26 (halfway, rounds to even)

     */
    private static func roundToTwoDecimalPlaces(_ value: Decimal) -> Decimal {
        var roundedValue = Decimal()
        var originalValue = value
        NSDecimalRound(&roundedValue, &originalValue, 2, .bankers)
        return roundedValue
    }

    static func localizedStringWithoutCurrencyCode(from decimal: Decimal) -> String? {
        let formatter = NumberFormatter.twoDecimalPriceFormatter
        return formatter.string(from: NSDecimalNumber(decimal: decimal))
    }
}

extension Price: Equatable {}

extension Price {
    struct PriceCurrencyMismatchError: Error {}

    static func * (price: Price, int: Int) -> Price {
        return Price(value: price.value * Decimal(int),
                     currencyCode: price.currencyCode)
    }

    static func + (lhs: Price, rhs: Price) throws -> Price {
        if lhs.currencyCode != rhs.currencyCode {
            throw PriceCurrencyMismatchError()
        }

        return Price(value: lhs.value + rhs.value,
                     currencyCode: lhs.currencyCode)
    }

    static func - (lhs: Price, rhs: Price) throws -> Price {
        if lhs.currencyCode != rhs.currencyCode {
            throw PriceCurrencyMismatchError()
        }

        return Price(value: lhs.value - rhs.value,
                     currencyCode: lhs.currencyCode)
    }

    static func max(_ lhs: Price, _ rhs: Price) -> Price {
        return lhs.value >= rhs.value ? lhs : rhs
    }
}

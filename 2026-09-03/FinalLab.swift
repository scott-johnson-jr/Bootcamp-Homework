import Foundation

func div(_ message: String = "", _ symbol: String = "=") {
    let maxLineLen = 120
    let msg = message.trimmingCharacters(in: .whitespacesAndNewlines) == "" ? "" : " \(message) "
    let msgLen = msg.count
    let halfDiv = String(repeating: symbol, count: (maxLineLen - msgLen) / 2)
    var div = "\(halfDiv)\(msg)\(halfDiv)"

    if div.count < maxLineLen {
        div = "\(div)\(symbol)"
    }

    print(div)
}



protocol Summarizable {
    var summary: String { get }
}

extension Summarizable {
    func printSummary() {
        print(summary)
    }
}

protocol AccountOperations {
    func deposit(amount: Double) throws
    func withdraw(amount: Double) throws
    func transfer(amount: Double, to: BankAccount) throws
}

enum AccountOperationsError: LocalizedError {
    case invalidAmount
    case insufficientFunds(available: Double, required: Double)
    case accountInactive
    case transferToSameAccount
    case dailyLimitExceeded(limit: Double)
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Invalid amount"
        case .insufficientFunds(available: let available, required: let required):
            return "Insufficient funds. Available: \(available), required: \(required)"
        case .accountInactive:
            return "Account is inactive"
        case .transferToSameAccount:
            return "Cannot transfer to the same account"
        case .dailyLimitExceeded(limit: let limit):
            return "Daily limit exceeded. Limit: \(limit)"
        }
    }
}



enum TransactionType: String, CaseIterable, Codable {
    case credit
    case debit
    case transfer
    case fee

    var isExpense: Bool {
        switch self {
        case .debit, .fee: return true
        default: return false
        }
    }
}

enum TransactionStatus: String, Codable {
    case pending
    case completed
    case failed
    case cancelled

    var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled: return true
        case .pending: return false
        }
    }
}

struct Transaction: Identifiable, Codable, Equatable, Hashable, Summarizable {
    var id: String = UUID().uuidString
    let date: Date
    let amount: Double
    let description: String
    let type: TransactionType
    var status: TransactionStatus = .completed
    var category: String?
    var merchantName: String?

    var summary: String {
        return "\(formattedDate) \(formattedAmount)"
    }

    var formattedAmount: String {
        "\(type.isExpense ? "-" : "+")$\(String(format: "%.2f", amount))"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var resolvedCategory: String { category ?? "Uncategorized" }

    init(date: Date, amount: Double, description: String, type: TransactionType,status: TransactionStatus, category: String?, merchantName: String?) {
        self.date = date
        self.amount = amount
        self.description = description
        self.type = type
        self.status = status
        self.category = category
        self.merchantName = merchantName
    }
}

let t1 = Transaction(date: Date(), amount: 25.00, description: "Groceries", type: .debit, status: .completed, category: "food", merchantName: "Giant Eagle")
print(t1)



class BankAccount: Identifiable, AccountOperations, Summarizable {
    var id: String
    var accountNumber: String
    let accountType: String
    var nickname: String?
    var balance: Double
    var availableBalance: Double
    let currency: String
    let isActive: Bool
    var transactions: [Transaction] = []

    init(id: String, accountNumber: String, accountType: String, nickname: String?,
                     initialBalance: Double, currency: String = "USD", isActive: Bool = true) {
        self.id = id
        self.accountNumber = accountNumber
        self.accountType = accountType
        self.nickname = nickname
        self.balance = initialBalance
        self.availableBalance = initialBalance
        self.currency = currency
        self.isActive = isActive
    }

    var displayName: String { nickname ?? accountType.capitalized }

    var maskedAccountNumber: String { "****" + accountNumber.suffix(4) }

    var summary: String {
        "\(displayName) (\(maskedAccountNumber)): \(formattedBalance)"
    }

    var formattedBalance: String {
        "\(currency) \(String(format: "%.2f", balance))"
    }
    
    var recentTransactions: [Transaction] {
        transactions.sorted { $0.date > $1.date }.prefix(5).map { $0 }
    }
    var pendingCount: Int {
        transactions.filter { $0.status == .pending }.count
    }

    func deposit(amount: Double) throws {
        guard amount > 0 else { throw AccountOperationsError.invalidAmount }
        guard isActive else { throw AccountOperationsError.accountInactive }
        balance += amount
        availableBalance += amount
    }

    func withdraw(amount: Double) throws {
        guard amount > 0 else { throw AccountOperationsError.invalidAmount }
        guard isActive else { throw AccountOperationsError.accountInactive }
        guard availableBalance >= amount else {
            throw AccountOperationsError.insufficientFunds(available: availableBalance, required: amount)
        }
        balance -= amount
        availableBalance -= amount
    }

    func transfer(amount: Double, to other: BankAccount) throws {
        guard self.id != other.id else {
            throw AccountOperationsError.transferToSameAccount
        }
        try self.withdraw(amount: amount)
        try other.deposit(amount: amount)
    }
    
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        
        if transaction.type.isExpense {
            balance -= transaction.amount
        } else {
            balance += transaction.amount
        }
        
        availableBalance = balance
    }
}

div("Section 5")

protocol AnalyticsProvider {
    var totalCredits: Double { get }
    var totalDebits: Double { get }
    var netFlow: Double { get }
    var largestTransaction: Transaction? { get }
    func monthlyTotal(month: Int, year: Int) -> Double
    func transactionsByCategory() -> [String: [Transaction]]
    }
struct AccountAnalytics: AnalyticsProvider {
    let transactions: [Transaction]
    var totalCredits: Double {
        return transactions.filter { !$0.type.isExpense }.reduce(0) { $0 + $1.amount }
    }
    var totalDebits: Double {
        return transactions.filter { $0.type.isExpense}.reduce(0) { $0 + $1.amount }
    }
    var netFlow: Double {
        return totalCredits - totalDebits
    }
    var largestTransaction: Transaction? {
        return transactions.max(by: { $0.amount < $1.amount })
    }
    func monthlyTotal(month: Int, year: Int) -> Double {
        let calendar = Calendar.current
        return transactions.filter {
            let components = calendar.dateComponents([.month, .year], from: $0.date)
            return components.month == month && components.year == year
        }.reduce(0) { $0 + $1.amount }
    }
    func transactionsByCategory() -> [String: [Transaction]] {
        return Dictionary(grouping: transactions, by: \.resolvedCategory)
    }
}

let t2 = Transaction(date: Date(), amount: 1100, description: "Paycheck", type: .credit, status: .completed, category: "Income", merchantName: "PNC")

print(t2)


div("Section 6")

func reportResults<T: Summarizable>(_ items: [T], title: String) {
    print("=== \(title) ===")
    print("\(items.count) items")
    for item in items {
        item.printSummary()
    }
    print("=== End of === \(title)")
}

let analytics = AccountAnalytics(transactions: [t1, t2])

reportResults(analytics.transactions, title: "Recent Transactions")

div("Section 7")

func runlabDemo() {
    let checking = BankAccount(id: "01", accountNumber: "12345", accountType: "CHECKING", nickname: nil, initialBalance: 3_500.00)
    let savings = BankAccount(id: "02", accountNumber: "54321", accountType: "SAVINGS", nickname: nil, initialBalance: 12_000.00)
    
    
    let transaction1 = Transaction(date: Date(), amount: 100.00, description: "Direct Deposit", type: .credit, status: .completed, category: "Income", merchantName: "PNC")
    let transaction2 = Transaction(date: Date(), amount: 200.00, description: "Groceries", type: .debit, status: .completed, category: "Food", merchantName: "Whole Foods")
    let transaction3 = Transaction(date: Date(), amount: 8.00, description: "Coffee", type: .debit, status: .completed, category: "Breakfast", merchantName: "Dunkin Donuts")
    let transaction4 = Transaction(date: Date(), amount: 2.50, description: "Late Fee", type: .debit, status: .completed, category: "Fees", merchantName: "CapitalOne")
    let transaction5 = Transaction(date: Date(), amount: 130.00, description: "Bank Transfer", type: .transfer, status: .completed, category: "Transfer", merchantName: nil)
    
    do {
        try checking.withdraw(amount: 5_000.00)
    } catch {
        print(error.localizedDescription)
    }
    
    do {
        try checking.deposit(amount: -10.00)
    } catch {
        print(error.localizedDescription)
    }
    
    do {
        try checking.transfer(amount: 100.00, to: checking)
    } catch {
        print(error.localizedDescription)
    }
    
    let checkingAnalytics = AccountAnalytics(transactions: checking.transactions)

        print("Total credits: \(checkingAnalytics.totalCredits)")
        print("Total debits: \(checkingAnalytics.totalDebits)")
        print("Net flow: \(checkingAnalytics.netFlow)")

        if let largest = checkingAnalytics.largestTransaction {
            print("Largest transaction: \(largest.description), \(largest.formattedAmount)")
        }

        for (category, transactions) in checkingAnalytics.transactionsByCategory() {
            print("\(category): \(transactions.count)")
        }
    reportResults([checking, savings], title: "All Accounts")
    
    let checkingAlias = checking
       try? checkingAlias.deposit(amount: 100.00)
       print("checking balance: \(checking.balance)")
       print("checkingAlias balance: \(checkingAlias.balance)")
    
}

runlabDemo()



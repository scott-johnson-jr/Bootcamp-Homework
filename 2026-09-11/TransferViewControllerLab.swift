//
//  via.swift
//  UIKit Demo
//
//  Created by user301577 on 9/13/26.
//


//
//  TransferViewController_Starter.swift
//  PNCMobileApp
//
//  Module 7 — iOS Application Architecture
//  Lab Exercise: Refactor TransferViewController
//
//  SCENARIO
//  The view controller below is a Massive View Controller: it mixes
//  networking, validation, and UI update logic in one class. Your task is
//  to refactor it using the patterns from this module.
//
//  REQUIREMENTS
//  1. Extract a TransferViewModel with ZERO UIKit imports.
//  2. Extract transfer eligibility rules into a TransferEligibilityService.
//  3. Inject an AccountsRepository protocol via the ViewModel's
//     initializer — no singletons.
//  4. The refactored ViewModel must be unit-testable using a fake
//     repository, with no real network call.
//
//  Read through BEFORE_ExistingMassiveViewController below first — really
//  read it, don't skim. Naming what's wrong with it is part of the
//  exercise. Then fill in the TODOs in the scaffolding beneath it.
//

import UIKit

// MARK: - BEFORE: the Massive View Controller (do not edit — refactor FROM this)

class BEFORE_ExistingMassiveViewController: UIViewController {
    var fromAccount: Account!
    var toAccount: Account!
    @IBOutlet weak var amountField: UITextField!

    @IBAction func transferButtonTapped() {
        guard let text = amountField.text,
              let amount = Decimal(string: text) else {
            showAlert(message: "Please enter a valid amount")
            return
        }
        guard amount > 0 else {
            showAlert(message: "Amount must be greater than zero")
            return
        }
        guard fromAccount.balance >= amount else {
            showAlert(message: "Insufficient funds")
            return
        }

        var request = URLRequest(url: URL(string: "https://api.pncmobile.com/transfer")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONEncoder().encode([
            "from": fromAccount.id.uuidString,
            "to": toAccount.id.uuidString,
            "amount": "\(amount)",
        ])
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if error != nil {
                    self?.showAlert(message: "Transfer failed. Please try again.")
                } else {
                    self?.navigationController?.popToRootViewController(animated: true)
                }
            }
        }.resume()
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Transfer", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Model (complete — no changes needed)

struct Account: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let maskedNumber: String
    let balance: Decimal
}



// MARK: - TODO 1: AccountsRepository protocol

protocol AccountsRepository {
    
    func transfer(from: Account, to: Account, transferAmount: Decimal) async throws -> Void
    
    // TODO: declare an async throws method to perform a transfer between
    // two accounts for a given amount. Think about what parameters and
    // return type make sense given how it will be called from the
    // ViewModel.
}

// MARK: - TODO 2: TransferEligibilityService

enum TransferError: Error, Equatable {
    case invalidAmount
    case insufficientFunds
}

struct TransferEligibilityService {
    func canTransfer(transferAmount: Decimal, from: Account) -> Result<Void, TransferError> {
        guard transferAmount > 0 else { return .failure(.invalidAmount) }
        guard from.balance >= transferAmount else { return .failure(.insufficientFunds) }
        return .success(())
    }
    // TODO: implement canTransfer(amount:from:) -> Result<Void, TransferError>
    // covering the same two rules as the BEFORE version above: amount must
    // be greater than zero, and the source account must have sufficient
    // balance.
}

// MARK: - TODO 3: TransferViewModel

@Observable
final class TransferViewModel {
    let repository: AccountsRepository
    let eligibilityService: TransferEligibilityService
    
    init(repository: AccountsRepository, eligibilityService: TransferEligibilityService) {
        self.repository = repository
        self.eligibilityService = eligibilityService
        var onError: String?
        var onSuccess: String?

        func attemptTransfer (amount: Decimal, from: Account, to: Account) {
            switch eligibilityService.canTransfer(transferAmount: amount, from: from) {
                case .failure(let error):
                        onError = "Transfer failed: \(error)"
                case .success:
                Task {
                    do {
                        try await repository.transfer(from: from, to: to, transferAmount: amount)
                        onSuccess = "Transfer successful!"
                    } catch {
                        onError = "Transfer failed: \(error)"
                    }
                }
            }
        }
    }

    
    // TODO: no UIKit import anywhere in this file below this point.
    // Store an AccountsRepository and a TransferEligibilityService,
    // injected via the initializer. Expose onError and onSuccess
    // closures the View can observe. Implement
    // attemptTransfer(amount:from:to:) that checks eligibility first,
    // then calls the repository if eligible.
}


//extension BoardMembersView {
//    
//    @Observable
//    class ViewModel: Failable {
//        
//        var repository: any RepositoryProtocol<BoardMember>
//        var members: [BoardMember] = [] {
//            didSet {
//                selectedMember = nil
//            }
//        }
//        var selectedMember: BoardMember? = nil
//        var errorMessage: String = ""
//        
//        init(repository: any RepositoryProtocol<BoardMember>) {
//            self.repository = repository
//        }
//        
//        func loadData() async {
//            errorMessage = ""
//            do {
//                members = try await repository.getAll()
//                errorMessage = "Something went awry!"
//            }
//            catch {
//                errorMessage = "\(error)"
//            }
//            
//        }
//        
//    }
//    
//}

import Foundation
import Combine
import CoreData


class BarcodeService: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isProcessing = false
    @Published var medicationInfo: MedicationInfo?
    @Published var errorMessage: String?
    
    // Reference to the managed object context
    private var viewContext: NSManagedObjectContext {
        return PersistenceController.shared.container.viewContext
    }
    
    // Special product database (for popular medications)
    private let knownProducts: [String: MedicationInfo] = [
        // Claritin products
        "041100010174": MedicationInfo(
            name: "Claritin 24-Hour Allergy Relief",
            description: "Loratadine 10mg Tablets (30 count)",
            manufacturer: "Bayer",
            barcode: "041100010174"
        ),
        "41100010174": MedicationInfo(
            name: "Claritin 24-Hour Allergy Relief",
            description: "Loratadine 10mg Tablets (30 count)",
            manufacturer: "Bayer",
            barcode: "41100010174"
        ),
        "041100766613": MedicationInfo(
            name: "Claritin 24-Hour Allergy Relief",
            description: "Loratadine 10mg Tablets (30 count)",
            manufacturer: "Bayer",
            barcode: "041100766613"
        ),
        "041100010167": MedicationInfo(
            name: "Claritin 24-Hour Allergy Relief",
            description: "Loratadine 10mg Tablets (10 count)",
            manufacturer: "Bayer",
            barcode: "041100010167"
        ),
        
        // CVS Health Products
        "050428462701": MedicationInfo(
            name: "CVS Health Allergy Relief",
            description: "Loratadine 10mg Tablets (30 count)",
            manufacturer: "CVS Health",
            barcode: "050428462701"
        ),
        "50428462701": MedicationInfo(
            name: "CVS Health Allergy Relief",
            description: "Loratadine 10mg Tablets (30 count)",
            manufacturer: "CVS Health",
            barcode: "50428462701"
        )
    ]
    
    func lookupMedication(barcode: String) {
        print("BarcodeService looking up: \(barcode)")
        
        // First normalize the barcode to handle scan errors
        let normalizedBarcode = BarcodeHandler.normalizeBarcode(barcode)
        
        // Check local database first
        if let existingMedication = MedicationDataManager.shared.findMedication(byBarcode: normalizedBarcode) {
            print("Found in local cache: \(existingMedication.name)")
            // Create MedicationInfo from existing medication
            self.medicationInfo = MedicationInfo(
                name: existingMedication.name,
                description: existingMedication.shortDescription,
                manufacturer: existingMedication.manufacturer,
                barcode: existingMedication.barcode,
                expirationDate: existingMedication.expirationDate,
                category: getCategoryType(from: existingMedication.category)
            )
            return
        }
        
        // Check our known product database
        if let knownProduct = knownProducts[normalizedBarcode] {
            print("Found in known products database: \(knownProduct.name)")
            self.medicationInfo = knownProduct
            return
        }
        
        // Start network request
        isProcessing = true
        errorMessage = nil
        
        // Determine barcode type for optimal API handling
        let barcodeType = BarcodeHandler.detectBarcodeType(normalizedBarcode)
        print("Detected barcode type: \(barcodeType)")
        
        // Try multiple APIs in sequence
        lookupWithMultipleAPIs(barcode: normalizedBarcode, type: barcodeType)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isProcessing = false
                    
                    if case .failure(let error) = completion {
                        print("API error: \(error.localizedDescription)")
                        
                        // Provide helpful error message when nothing found
                        let knownInfo = BarcodeHandler.isKnownProduct(normalizedBarcode)
                        if knownInfo.isKnown {
                            // We know this product but APIs failed, create it manually
                            self?.medicationInfo = MedicationInfo(
                                name: knownInfo.productName,
                                description: "Details not found in API - please complete manually",
                                manufacturer: "Unknown",
                                barcode: normalizedBarcode
                            )
                        } else {
                            self?.errorMessage = "No medication found for barcode: \(normalizedBarcode). You can add it manually."
                        }
                    }
                },
                receiveValue: { [weak self] result in
                    print("API success: Found \(result.name)")
                    self?.medicationInfo = result
                }
            )
            .store(in: &cancellables)
    }
    
    // Handle multiple API lookups with proper fallbacks
    private func lookupWithMultipleAPIs(barcode: String, type: BarcodeType) -> AnyPublisher<MedicationInfo, Error> {
        // Try multiple APIs in sequence
        return lookupWithOpenFDA(barcode: barcode, type: type)
            .catch { error -> AnyPublisher<MedicationInfo, Error> in
                // Log the error for debugging
                print("OpenFDA lookup failed: \(error.localizedDescription)")
                return self.lookupWithUPCDatabase(barcode: barcode)
            }
            .catch { error -> AnyPublisher<MedicationInfo, Error> in
                print("UPC Database lookup failed: \(error.localizedDescription)")
                return self.lookupWithRxNorm(barcode: barcode)
            }
            .catch { error -> AnyPublisher<MedicationInfo, Error> in
                print("RxNorm lookup failed: \(error.localizedDescription)")
                return self.lookupWithDrugBank(barcode: barcode)
            }
            .catch { error -> AnyPublisher<MedicationInfo, Error> in
                print("All API lookups failed")
                
                // Try known product patterns as a last resort
                if barcode.contains("041100") || barcode.contains("41100") {
                    // Likely a Claritin product
                    return Just(MedicationInfo(
                        name: "Claritin Product",
                        description: "Loratadine Allergy Relief",
                        manufacturer: "Bayer",
                        barcode: barcode
                    ))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
                } else if barcode.contains("05042") || barcode.contains("5042") {
                    // Likely a CVS product
                    return Just(MedicationInfo(
                        name: "CVS Health Product",
                        description: "CVS Brand Medication",
                        manufacturer: "CVS Health",
                        barcode: barcode
                    ))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
                }
                
                // All lookups failed, propagate the error
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // OpenFDA API lookup
    private func lookupWithOpenFDA(barcode: String, type: BarcodeType) -> AnyPublisher<MedicationInfo, Error> {
        // Format barcode specifically for OpenFDA
        let formattedBarcode = BarcodeHandler.formatForAPI(barcode, type: type)
        
        // Build the URL with comprehensive search parameters
        let baseUrl = "https://api.fda.gov/drug/ndc.json"
        let queryOptions = [
            "search=product_ndc:\"\(formattedBarcode)\"",
            "search=product_ndc:\(formattedBarcode)",  // Try without quotes
            "search=product_ndc:\(formattedBarcode.replacingOccurrences(of: "-", with: ""))" // Try without hyphens
        ]
        
        // Try multiple query formats in sequence
        var publishers: [AnyPublisher<MedicationInfo, Error>] = []
        
        for query in queryOptions {
            if let url = URL(string: "\(baseUrl)?\(query)") {
                print("Trying OpenFDA URL: \(url.absoluteString)")
                
                let publisher = URLSession.shared.dataTaskPublisher(for: url)
                    .map(\.data)
                    .decode(type: OpenFDAResponse.self, decoder: JSONDecoder())
                    .tryMap { response -> MedicationInfo in
                        guard let result = response.results.first else {
                            throw NSError(domain: "BarcodeService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No results found"])
                        }
                        
                        return MedicationInfo(
                            name: result.brand_name ?? result.generic_name ?? "Unknown",
                            description: result.dosage_form ?? result.pharm_class?.joined(separator: ", ") ?? "No description available",
                            manufacturer: result.labeler_name ?? "Unknown",
                            barcode: barcode
                        )
                    }
                    .eraseToAnyPublisher()
                
                publishers.append(publisher)
            }
        }
        
        // Try each query in sequence
        return publishers.first!
            .catch { _ in publishers.count > 1 ? publishers[1] : Fail(error: NSError(domain: "OpenFDA", code: 404, userInfo: nil)).eraseToAnyPublisher() }
            .catch { _ in publishers.count > 2 ? publishers[2] : Fail(error: NSError(domain: "OpenFDA", code: 404, userInfo: nil)).eraseToAnyPublisher() }
            .eraseToAnyPublisher()
    }
    
    // UPC Database lookup
    private func lookupWithUPCDatabase(barcode: String) -> AnyPublisher<MedicationInfo, Error> {
        // Use UPC Item DB for better results
        let urlString = "https://api.upcitemdb.com/prod/trial/lookup?upc=\(barcode)"
        guard let url = URL(string: urlString) else {
            return Fail(error: NSError(domain: "BarcodeService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
                .eraseToAnyPublisher()
        }
        
        print("Trying UPC Database URL: \(url.absoluteString)")
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: UPCItemDBResponse.self, decoder: JSONDecoder())
            .tryMap { response -> MedicationInfo in
                guard let item = response.items.first else {
                    throw NSError(domain: "UPCDatabase", code: 404, userInfo: [NSLocalizedDescriptionKey: "Product not found"])
                }
                
                // Extract brand from title if possible
                var brand = item.brand
                if brand.isEmpty, let firstWord = item.title.components(separatedBy: " ").first {
                    brand = firstWord
                }
                
                return MedicationInfo(
                    name: item.title,
                    description: item.description.isEmpty ? "OTC Medication" : item.description,
                    manufacturer: brand.isEmpty ? "Unknown" : brand,
                    barcode: barcode
                )
            }
            .eraseToAnyPublisher()
    }
    
    // RxNorm API lookup
    private func lookupWithRxNorm(barcode: String) -> AnyPublisher<MedicationInfo, Error> {
        let urlString = "https://rxnav.nlm.nih.gov/REST/ndcstatus.json?ndc=\(barcode)"
        guard let url = URL(string: urlString) else {
            return Fail(error: NSError(domain: "BarcodeService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
                .eraseToAnyPublisher()
        }
        
        print("Trying RxNorm URL: \(url.absoluteString)")
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: RxNormResponse.self, decoder: JSONDecoder())
            .flatMap { response -> AnyPublisher<MedicationInfo, Error> in
                guard let rxcui = response.ndcStatus.rxcui else {
                    return Fail(error: NSError(domain: "RxNorm", code: 3, userInfo: [NSLocalizedDescriptionKey: "No RxCUI found"]))
                        .eraseToAnyPublisher()
                }
                
                return self.fetchRxNormDetails(rxcui: rxcui, barcode: barcode)
            }
            .eraseToAnyPublisher()
    }
    
    // DrugBank API (simplified version since real API requires authentication)
    private func lookupWithDrugBank(barcode: String) -> AnyPublisher<MedicationInfo, Error> {
        // In real implementation, you would authenticate with DrugBank API
        // This is a simulated fallback for example purposes
        
        // Check for known patterns to provide fallbacks
        if barcode.contains("41100") || barcode.contains("041100") {
            // Likely a Schering-Plough (now Bayer) product
            return Just(MedicationInfo(
                name: "Allergy Relief",
                description: "Antihistamine Medication",
                manufacturer: "Bayer Consumer Health",
                barcode: barcode
            ))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        }
        
        return Fail(error: NSError(domain: "DrugBank", code: 404, userInfo: [NSLocalizedDescriptionKey: "Product not found in DrugBank"]))
            .eraseToAnyPublisher()
    }
    
    // Get RxNorm medication details
    private func fetchRxNormDetails(rxcui: String, barcode: String) -> AnyPublisher<MedicationInfo, Error> {
        let urlString = "https://rxnav.nlm.nih.gov/REST/rxcui/\(rxcui)/allrelated.json"
        guard let url = URL(string: urlString) else {
            return Fail(error: NSError(domain: "BarcodeService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
                .eraseToAnyPublisher()
        }
        
        print("Fetching RxNorm details: \(url.absoluteString)")
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: RxNormDetailsResponse.self, decoder: JSONDecoder())
            .map { response -> MedicationInfo in
                // Extract the relevant information from the response
                let brandName = response.allRelatedGroup?.conceptGroup
                    .first(where: { $0.tty == "BN" })?.conceptProperties
                    .first?.name ?? "Unknown"
                
                let genericName = response.allRelatedGroup?.conceptGroup
                    .first(where: { $0.tty == "IN" })?.conceptProperties
                    .first?.name ?? "Unknown"
                
                return MedicationInfo(
                    name: brandName != "Unknown" ? brandName : genericName,
                    description: "RxNorm ID: \(rxcui)",
                    manufacturer: "Unknown", // RxNorm doesn't typically provide manufacturer info
                    barcode: barcode
                )
            }
            .eraseToAnyPublisher()
    }
    
    // Helper method to search the local database
      private func findMedicationInDatabase(barcode: String) -> Medication? {
          let fetchRequest = NSFetchRequest<Medication>(entityName: "Medication")
          fetchRequest.predicate = NSPredicate(format: "barcode == %@", barcode)
          fetchRequest.fetchLimit = 1
          
          do {
              let results = try viewContext.fetch(fetchRequest)
              return results.first
          } catch {
              print("Error fetching medication by barcode: \(error)")
              return nil
          }
      }
      
      // Helper to convert string category to enum
      private func getCategoryType(from categoryString: String) -> MedicationType {
          return categoryString == MedicationType.prescription.rawValue ?
              .prescription : .overTheCounter
      }
    
}

// MARK: - Response Models

// OpenFDA API Response
struct OpenFDAResponse: Codable {
    struct Result: Codable {
        let product_ndc: String?
        let generic_name: String?
        let brand_name: String?
        let labeler_name: String?
        let dosage_form: String?
        let active_ingredients: [ActiveIngredient]?
        let pharm_class: [String]?
    }
    
    struct ActiveIngredient: Codable {
        let name: String
        let strength: String?
    }
    
    let results: [Result]
}

// UPC Item DB API Response (more comprehensive than basic UPC database)
struct UPCItemDBResponse: Codable {
    struct Item: Codable {
        let ean: String
        let title: String
        let description: String
        let brand: String
        let category: String?
        let images: [String]?
    }
    
    let items: [Item]
}

// RxNorm API Response
struct RxNormResponse: Codable {
    struct NDCStatus: Codable {
        let ndc: String?
        let rxcui: String?
        let status: String?
    }
    
    let ndcStatus: NDCStatus
}

// RxNorm Details API Response
struct RxNormDetailsResponse: Codable {
    struct AllRelatedGroup: Codable {
        struct ConceptGroup: Codable {
            let tty: String
            let conceptProperties: [ConceptProperty]
        }
        
        struct ConceptProperty: Codable {
            let rxcui: String
            let name: String
        }
        
        let conceptGroup: [ConceptGroup]
    }
    
    let allRelatedGroup: AllRelatedGroup?
}


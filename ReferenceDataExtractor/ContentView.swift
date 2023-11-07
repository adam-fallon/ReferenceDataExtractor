import Foundation
import SwiftUI
import MapKit
import UniformTypeIdentifiers

extension MKMapItem: Identifiable {
    public var id: UUID { UUID() }
}

struct ContentView: View {
    @State var mapItems: [MapItem]?
    @State var searchText: String = "Coffee"
    @State var lat: String = "54.5973"
    @State var lng: String = "-5.9301"
    @State var selection = Set<MapItem.ID>()
    
    func getReferenceData(_ searchText: String) {
        mapItems = []
        var localSearch: MKLocalSearch?
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchText
        
        guard let latitude = Double(lat), let longitude = Double(lng) else {
            return
        }
        
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: center, span: span)
        searchRequest.region = region
        
        localSearch?.cancel()
        localSearch = MKLocalSearch(request: searchRequest)
        localSearch?.start { (response, error) in
            guard error == nil else {
                return
            }
            
            
            mapItems = response?.mapItems.map {
                MapItem.init(
                    name: $0.name ?? "Unknown Name",
                    url: $0.url?.absoluteString ?? "Unknown URL",
                    placemark: "\($0.placemark.coordinate.latitude)|\($0.placemark.coordinate.longitude)"
                )
            }
        }
    }
    
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack {
                    Form {
                        TextField(
                            "Category",
                            text: $searchText
                        )
                        TextField(
                            "Latitude",
                            text: $lat
                        )
                        TextField(
                            "Longitude",
                            text: $lng
                        )
                    }
                    .onSubmit {
                        getReferenceData(searchText)
                    }
                    .disableAutocorrection(true)
                    .border(.secondary)
                }
            }
            if let mapItems = mapItems {
                Table(mapItems, selection: $selection) {
                    TableColumn("Name", value: \.name)
                    TableColumn("URL", value: \.url)
                    TableColumn("Lat/Long", value: \.placemark)
                }
                .focusable()
                .toolbar {
                    Button(action: {
                        if selection.count == 0 {
                            return
                        }
                        
                        var output = "name,url,latlong\n"
                        mapItems
                            .filter {
                                selection.contains($0.id)
                            }.forEach {
                                output += "\($0.name),\($0.url),\($0.placemark)\n"
                            }
                        
                        output = output.replacingOccurrences(of: "’", with: "'")
                                                                        
                        DispatchQueue.main.async {
                            let pasteboard = NSPasteboard.general
                            pasteboard.declareTypes([.string], owner: nil)
                            pasteboard.setString(output, forType: .string)
                        }
                    }) {
                        Text("Copy Selected Rows")
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

class MapItem: NSObject, Codable, Identifiable, NSSecureCoding {
        static var supportsSecureCoding: Bool = true

    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "text")
        aCoder.encode(url, forKey: "url")
        aCoder.encode(placemark, forKey: "placemark")
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard
            let name = aDecoder.decodeObject(of: [NSString.self], forKey: "name") as? String,
            let url = aDecoder.decodeObject(of: [NSString.self], forKey: "url") as? String,
            let placemark = aDecoder.decodeObject(of: [NSDate.self], forKey: "placemark") as? String
        else {
            return nil
        }
                
        self.name = name
        self.url = url
        self.placemark = placemark
    }
    
    var id: UUID = UUID()
    var name: String
    var url: String
    var placemark: String
    
    init(name: String, url: String, placemark: String) {
        self.name = name
        self.url = url
        self.placemark = placemark
    }
}

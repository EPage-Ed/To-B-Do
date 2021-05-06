//
//  SelectPrinterVC.swift
//  To-B-Do
//
//  Created by Edward Arenberg on 5/6/21.
//

import UIKit
import BrotherBSwift

protocol SelectPrinterVCDelegate : AnyObject {
  func printerSelected(printer: BrotherPrinter) // , paper: Paper?)
}

extension SelectPrinterVC : UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    printers.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "PrinterCell", for: indexPath)
    
    let printer = printers[indexPath.row]
    cell.textLabel?.font = UIFont.systemFont(ofSize: 20)
    cell.textLabel?.text = printer.name
    
    return cell
  }
}

extension SelectPrinterVC : UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let selectedPrinter = printers[indexPath.row]
    switch brother.paper(for: selectedPrinter) {
    case .failure(let e):
      print(e.localizedDescription)
      paper = nil
    case .success(let paper):
      print(paper.0)
      print(paper.1)
      self.paperSize = paper.0
      self.paper = paper.1
      break
    }
    self.selectedPrinter = selectedPrinter
  }
}

extension SelectPrinterVC : NetServiceDelegate {
  func netServiceDidResolveAddress(_ sender: NetService) {
    print(sender.hostName, sender.port)
    scanPrinters()
  }
  func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
    print(errorDict)
    scanPrinters()
  }
  
  func netServiceDidStop(_ sender: NetService) {
    print("Stopped")
    scanPrinters()
  }
}


class SelectPrinterVC: UIViewController {
  
  weak var delegate : SelectPrinterVCDelegate?
  
  private var printers = [BrotherPrinter]() {
    didSet {
      printerTV.reloadData()
    }
  }
  private var paper : Paper?
  private var paperSize : Int?
  private var selectedPrinter : BrotherPrinter? {
    didSet {
//      printButton.isEnabled = selectedPrinter != nil
      delegate?.printerSelected(printer: selectedPrinter!) // , paper: paper)
    }
  }

  private var brother = BrotherSwift()
  private let netService = NetService(domain: "local.", type: "_printer._tcp.", name: "myService")

  @IBOutlet weak var spinner: UIActivityIndicatorView!
  @IBOutlet weak var printerTV: UITableView!
  
  func genImage(text: String, on printer: BrotherPrinter, font: UIFont = UIFont.systemFont(ofSize: UIFont.labelFontSize)) -> UIImage? {
    guard let paper = paper else { print("Unknown Paper"); return nil }
    let w = paper.w  // mm
    let wd = CGFloat(w) * (300.0 / 25.4) // dpmm
    print(wd)
    
    return brother.imageText(text: text, on: printer, width: wd, font: font)
  }
  
  func printImage(image:UIImage, on printer: BrotherPrinter) -> Result<Void,BrotherSwift.PrintError> {
    guard let paperSize = paperSize else { print("Unknown Paper Size"); return .failure(.unsupportedPaper) }
    brother.settings.labelSize = paperSize
    return brother.printImage(image: image, on: printer)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
  }
  
  private func scanPrinters() {
    brother.searchPrinters(callback: { printers in
      print("Search Done")
//      print(self.brother.devices.map { $0.description })
//      print(printers)
      self.printers = printers
      self.spinner.stopAnimating()
    })
  }

  func getPrinter() {
    spinner.startAnimating()
    netService.delegate = self
    netService.resolve(withTimeout: 3)
  }
  
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destination.
   // Pass the selected object to the new view controller.
   }
   */
  
}

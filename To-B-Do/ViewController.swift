//
//  ViewController.swift
//  To-B-Do
//
//  Created by Edward Arenberg on 5/6/21.
//

import UIKit
import BrotherBSwift

extension ViewController : SelectPrinterVCDelegate {
  func printerSelected(printer: BrotherPrinter) { // }, paper: Paper?) {
//    self.paper = paper
    self.selectedPrinter = printer
    selectPrinterView.isHidden = true
    printList()
  }
}

extension ViewController : UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return todos.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoCell")!

    cell.textLabel?.text = todos[indexPath.row]
    
    return cell
  }

  
}

extension ViewController : UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      tableView.beginUpdates()
      todos.remove(at: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .fade)
      tableView.endUpdates()
    }
  }
  
}

class ViewController: UIViewController {
  
  private var todos = [String]() {
    didSet {
      todoTV.reloadData()
      UserDefaults.standard.setValue(todos, forKey: "ToDoList")
    }
  }

  @IBOutlet weak var selectPrinterView: UIView! {
    didSet {
      selectPrinterView.isHidden = true
      selectPrinterView.layer.borderWidth = 2
      selectPrinterView.layer.borderColor = UIColor.lightGray.cgColor
      selectPrinterView.layer.cornerRadius = 9
      selectPrinterView.layer.masksToBounds = true
    }
  }
  private var printerVC : SelectPrinterVC!
  //  var paper : Paper?
  private var selectedPrinter : BrotherPrinter? {
    didSet {
      printButton.isEnabled = selectedPrinter != nil
      printButton.alpha = selectedPrinter != nil ? 1 : 0.5
    }
  }
  
  @IBOutlet weak var todoTV: UITableView! {
    didSet {
      todoTV.layer.borderWidth = 2
      todoTV.layer.borderColor = UIColor.lightGray.cgColor
      todoTV.layer.cornerRadius = 9
      todoTV.layer.masksToBounds = true
    }
  }
  
  @IBOutlet weak var addButton: UIButton! {
    didSet {
      addButton.layer.cornerRadius = 9
      addButton.layer.masksToBounds = true
    }
  }
  @IBAction func addHit(_ sender: UIButton) {
    let ac = UIAlertController(title: "Add Task", message: nil, preferredStyle: .alert)
    ac.addTextField(configurationHandler: { tf in
      tf.placeholder = "Task"
      tf.autocapitalizationType = .words
      tf.clearButtonMode = .whileEditing
    })
    ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    ac.addAction(UIAlertAction(title: "Add", style: .default) { action in
      guard let text = ac.textFields?.first?.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return }
      self.todos.append(text)
    })
    present(ac, animated: true, completion: nil)
  }
  

  @IBOutlet weak var printButton: UIButton! {
    didSet {
      printButton.layer.cornerRadius = 9
      printButton.layer.masksToBounds = true
    }
  }
  @IBAction func printHit(_ sender: UIButton) {
    
    selectPrinterView.isHidden = false
    printerVC.getPrinter()

  }
  
  private func printList() {
    
    func image(with view: UIView) -> UIImage? {
      UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
      defer { UIGraphicsEndImageContext() }
      if let context = UIGraphicsGetCurrentContext() {
        view.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        return image
      }
      return nil
    }
    
    var todoImages = [UIImage]()
    
    for todo in todos {
      let tdv = ToDoView.instanceFromNib()
      tdv.todoLabel.text = todo
    
      guard let img = image(with: tdv) else { continue }
      todoImages.append(img)
    }

    if let img = UIImage.compositeImages(images: todoImages, horizontal: false) {
      print(img)
      switch printerVC.printImage(image: img, on: selectedPrinter!) {
      case .failure(let e):
        let ac = UIAlertController(title: "Error", message: e.localizedDescription, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(ac, animated: true)
      case .success(()):
        break
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    printerVC = children.first { $0 is SelectPrinterVC } as? SelectPrinterVC
    printerVC.delegate = self
    
    if let list = UserDefaults.standard.array(forKey: "ToDoList") as? [String] {
      todos = list
    }
  }


}

class ToDoView: UIView {
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var todoLabel: UILabel!
  
  class func instanceFromNib() -> ToDoView {
    return UINib(nibName: "ToDoView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! ToDoView
  }
}

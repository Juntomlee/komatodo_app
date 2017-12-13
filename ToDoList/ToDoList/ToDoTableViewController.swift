//
//  ToDoTableViewController.swift
//  ToDoList
//
//  Created by jun lee on 9/26/17.
//  Copyright © 2017 jun lee. All rights reserved.
//

import UIKit
import UserNotifications

class ToDoTableViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    //MARK: Properties
    var todoArray = [ToDo]()
    var times = ["10min", "30min", "1hr", "2hr", "3hr", "6hr", "12hr", "24hr"]
    var reminderTime: Double = 600
    public var remainderTimer: Double = 0.0
    
    private func save(_ item: [ToDo]) {
        NSKeyedArchiver.archiveRootObject(todoArray, toFile: filePath)
    }
    
    var filePath: String {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
        return (url!.appendingPathComponent("Data").path)
    }
    
    //MARK: Private Methods
    //Setup sample list of ToDo List
    private func loadSampleTodos(){
        guard let todo1 = ToDo(listTitle: "Practice Swift", listItems: ["TableView", "Cell", "Delegate"], isCompleted: [false, true, true]) else {
            fatalError("Unable to instantiate 1")
        }
        guard let todo2 = ToDo(listTitle: "Laundry", listItems: ["Tshirts", "Pants", "Jacket"], isCompleted: [false, true, true]) else {
            fatalError("Unable to instantiate todo2")
        }
        guard let todo3 = ToDo(listTitle: "Grocery Shopping", listItems: ["Fruit", "Scallop", "Chips", "Beer"], isCompleted: [false, true, true, true]) else {
            fatalError("Unable to instantiate todo3")
        }
        todoArray += [todo1, todo2, todo3]
        save(todoArray)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor(red: 239/255, green: 154/255, blue: 154/255, alpha: 1)
//        loadSampleTodos() //Load sample ToDos when starting the app
        
        if let savedTodo = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? [ToDo] {
            todoArray = savedTodo
        }
        
        //Request Authorization for notification
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: {didallow, error in })
        
        //for Motion feature(shake to sort)
        self.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        save(todoArray)
    }

    // Sorting
    func sortList() {
        todoArray.sort(){$0.isCompleted.filter{$0 == false}.count > $1.isCompleted.filter{$0 == false}.count}
        // notify the table view the data has changed
        tableView.reloadData()
    }
    
    // Become FirstResponder when motion detected
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    // Enable detection of shake motion
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            sortList()
            save(todoArray)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // One section
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Total number of todos object
        return todoArray.count
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Change color for alternate cells
        if indexPath.row % 2 == 0{
//            cell.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
            cell.layer.backgroundColor = UIColor(red: 239/255, green: 154/255, blue: 154/255, alpha: 1).cgColor
        } else {
//            cell.backgroundColor = UIColor.white.withAlphaComponent(0.3)
            cell.layer.backgroundColor = UIColor(red: 255/255, green: 205/255, blue: 210/255, alpha: 1).cgColor
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as! ToDoTableViewCell
        
        var imageView : UIImageView
        imageView = UIImageView(frame:CGRect(x:0, y:0, width:15, height:15))
        imageView.image = UIImage(named:"arrow")
        cell.accessoryView = imageView
        
        //set todo constant to have value of todos array at indexpath.row
        let todo = todoArray[indexPath.row]
        
        //assign value to titlelabel
        cell.titleLabel.text = todo.listTitle
        let numberOfItemsLeft = todo.isCompleted.filter{$0 == false}.count
        if todo.isCompleted.isEmpty {
            cell.countLabel.text = "You do not have any item"
            cell.checkBoxButton.isSelected = false
        } else if numberOfItemsLeft == 0 {
            cell.countLabel.text = "You have nothing left to do!"
            cell.checkBoxButton.isSelected = true
        } else if numberOfItemsLeft == 1{
            cell.countLabel.text = "You have \(todo.isCompleted.filter{$0 == false}.count) item left"
            cell.checkBoxButton.isSelected = false
        } else if numberOfItemsLeft > 1{
            cell.countLabel.text = "You have \(todo.isCompleted.filter{$0 == false}.count) items left"
            cell.checkBoxButton.isSelected = false
        }
        return cell
    }
    
    //Delete using swipe
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {

        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Delete" , handler: { (action:UITableViewRowAction, indexPath: IndexPath) -> Void in
            tableView.beginUpdates()
            self.todoArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
            tableView.reloadData()
            self.save(self.todoArray)
        })
        let reminderAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Reminder" , handler: { (action:UITableViewRowAction, indexPath: IndexPath) -> Void in
            self.selectTimeForReminder(indexPath.row)
        })
        deleteAction.backgroundColor = UIColor.red
        reminderAction.backgroundColor = UIColor.blue
        return [deleteAction,reminderAction]
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        switch(segue.identifier ?? "") {
        case "AddItem":
            guard let todoDetailViewController = segue.destination as? ViewController else {
                fatalError()
            }
            let newArray = ToDo(listTitle: "", listItems: [], isCompleted: [])
            todoDetailViewController.todo = newArray
            
        case "ShowDetail":
            guard let todoDetailViewController = segue.destination as? ViewController else {
                fatalError()
            }
            guard let selectedTodoCell = sender as? ToDoTableViewCell else {
                fatalError()
            }
            guard let indexPath = tableView.indexPath(for: selectedTodoCell) else {
                fatalError()
            }
            
            let selectedToDo = todoArray[indexPath.row]
            todoDetailViewController.todo = selectedToDo

        default:
            fatalError()
        }
    }
    
    //MARK: Actions
    @IBAction func unwindToToDoList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? ViewController, let retrieveTodo = sourceViewController.todo{
            print(retrieveTodo.listTitle)
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                // Update an existing todo
                todoArray[selectedIndexPath.row] = retrieveTodo
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
                let encodedData = NSKeyedArchiver.archivedData(withRootObject: todoArray)
                UserDefaults.standard.set(encodedData, forKey: "todoArray")

            } else {
                // new todo
                let newIndexPath = IndexPath(row: todoArray.count, section: 0)
                todoArray.append(retrieveTodo)
                
                tableView.insertRows(at: [newIndexPath], with: .automatic)
                let encodedData = NSKeyedArchiver.archivedData(withRootObject: todoArray)
                UserDefaults.standard.set(encodedData, forKey: "todoArray")
            }
        }
    }
    
    // MARK: Pickerview delegate
    func selectTimeForReminder(_ selectedIndex: Int) {
        let alertView = UIAlertController(
            title: "Select Time",
            message: "\n\n\n\n\n\n\n\n\n",
            preferredStyle: .alert)
        
        let pickerView = UIPickerView(frame:
            CGRect(x: 0, y: 50, width: 260, height: 162))
        pickerView.dataSource = self
        pickerView.delegate = self
        
        // comment this line to use white color
        pickerView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        
        alertView.view.addSubview(pickerView)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {
            (result : UIAlertAction) -> Void in
            let todoContent = UNMutableNotificationContent()
            todoContent.title = self.todoArray[(selectedIndex)].listTitle
            todoContent.body = "You have " + "\(self.todoArray[(selectedIndex)].isCompleted.filter{$0 == false}.count)" + " item(s) left."
            todoContent.badge = 1
            
            let todoTrigger = UNTimeIntervalNotificationTrigger(timeInterval: self.reminderTime, repeats: false)
            let todoRequest = UNNotificationRequest(identifier: self.todoArray[selectedIndex].listTitle, content: todoContent, trigger: todoTrigger)
            
            UNUserNotificationCenter.current().add(todoRequest, withCompletionHandler: nil)
            
            //Notify user for reminder
            let alertController = UIAlertController(title: "Reminder", message: "You will be reminded in \(self.times[selectedIndex])", preferredStyle: UIAlertControllerStyle.alert)

            self.present(alertController, animated: true, completion: nil)
            let when = DispatchTime.now() + 2
            DispatchQueue.main.asyncAfter(deadline: when){
                // your code with delay
                alertController.dismiss(animated: true, completion: nil)
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil)
        
        alertView.addAction(okAction)
        alertView.addAction(cancelAction)
        
        present(alertView, animated: false, completion: { () in
            pickerView.frame.size.width = alertView.view.frame.size.width
        })
    }
    
    // MARK: Pickerview data source
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return times.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return times[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch times[row] {
        case "10min":
            reminderTime = 600
        case "30min":
            reminderTime = 1800
        case "1hr":
            reminderTime = 3600
        case "2hr":
            reminderTime = 7200
        case "3hr":
            reminderTime = 10800
        case "6hr":
            reminderTime = 21600
        case "12hr":
            reminderTime = 43200
        case "24hr":
            reminderTime = 86400
        default:
            print("Default")
        }
    }
}

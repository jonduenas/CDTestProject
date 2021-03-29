//
//  ViewController.swift
//  CDTestProject
//
//  Created by Jon Duenas on 3/29/21.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let cellIdentifier = "NoteCell"
    
    var coreDataStack: CoreDataStack!
    var dataSource: UITableViewDiffableDataSource<Int, NSManagedObjectID>!
    var fetchedResultsController: NSFetchedResultsController<NoteMO>! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let app = UIApplication.shared.delegate as! AppDelegate
        coreDataStack = app.coreDataStack
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "New Note", style: .plain, target: self, action: #selector(createNewNote))
        
        tableView.delegate = self
        configureDataSource()
        configureFetchedResultsController()
        fetchNotes()
    }
    
    private func configureDataSource() {
        let dataSource = UITableViewDiffableDataSource<Int, NSManagedObjectID>(tableView: tableView, cellProvider: { (tableView, indexPath, noteID) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath)
            
            do {
                let note = try self.coreDataStack.mainContext.existingObject(with: noteID) as! NoteMO
                cell.textLabel?.text = note.text
            } catch {
                print(error)
            }
            
            return cell
        })
        
        self.dataSource = dataSource
        tableView.dataSource = dataSource
    }
    
    @objc func createNewNote() {
        let newNote = NoteMO(context: coreDataStack.mainContext)
        newNote.text = "Test Note"
        newNote.date = Date()
        coreDataStack.saveContext()
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let noteID = dataSource.itemIdentifier(for: indexPath) else { return }
        
        do {
            let note = try self.coreDataStack.mainContext.existingObject(with: noteID) as! NoteMO
            print("Tapped \(note)")
        } catch {
            print(error)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {
    private func configureFetchedResultsController() {
        let request: NSFetchRequest<NoteMO> = NoteMO.fetchRequest()
        let sort = NSSortDescriptor(key: #keyPath(NoteMO.date), ascending: false)
        request.sortDescriptors = [sort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: coreDataStack.mainContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
    }
    
    private func fetchNotes() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error performing fetch - \(error.localizedDescription)")
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        guard let dataSource = tableView.dataSource as? UITableViewDiffableDataSource<Int, NSManagedObjectID> else {
            assertionFailure("The data source has not implemented snapshot support while it should")
            return
        }
        
        var snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
        let currentSnapshot = dataSource.snapshot() as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>

        // NSManagedObjectID doesn't change and isn't seen as needing updated. Instead, compare index between snapshots.
        let reloadIdentifiers: [NSManagedObjectID] = snapshot.itemIdentifiers.compactMap { itemIdentifier in
            // If the index of the NSManagedObjectID in the currentSnapshot is the same as the new snapshot, skip reloading
            guard let currentIndex = currentSnapshot.indexOfItem(itemIdentifier), let index = snapshot.indexOfItem(itemIdentifier), index == currentIndex else {
                return nil
            }
            // If the existing object doesn't have any updates, skip reloading
            guard let existingObject = try? controller.managedObjectContext.existingObject(with: itemIdentifier), existingObject.isUpdated else { return nil }
            
            return itemIdentifier
        }
        snapshot.reloadItems(reloadIdentifiers)
        
        // Only animate if there are already cells in the table
        let shouldAnimate = tableView.numberOfSections != 0
        dataSource.apply(snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>, animatingDifferences: shouldAnimate)
    }
}

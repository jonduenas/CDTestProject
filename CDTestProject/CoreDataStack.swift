//
//  CoreDataStack.swift
//  CDTestProject
//
//  Created by Jon Duenas on 3/29/21.
//

import Foundation
import CoreData

open class CoreDataStack {
    public static let modelName = "Model"
    
    public static let managedObjectModel: NSManagedObjectModel = {
        let bundle = Bundle(for: CoreDataStack.self)
        return NSManagedObjectModel.mergedModel(from: [bundle])!
    }()
    
    public init() {}
    
    public lazy var mainContext: NSManagedObjectContext = {
        return self.persistentContainer.viewContext
    }()
    
    public lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: CoreDataStack.modelName, managedObjectModel: CoreDataStack.managedObjectModel)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            container.viewContext.automaticallyMergesChangesFromParent = true
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    public func saveContext() {
        saveContext(mainContext)
    }
    
    public func saveContext(_ context: NSManagedObjectContext) {
        if context != mainContext {
            saveDerivedContext(context)
            return
        }
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            print("Core Data main context saved.")
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
    }
    
    public func saveDerivedContext(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            print("Core Data derived context saved.")
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        self.saveContext(self.mainContext)
    }
}

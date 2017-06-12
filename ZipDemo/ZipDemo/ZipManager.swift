//
//  Created by midmirror on 2017/2/14.
//  Copyright © 2017年 midmirror. All rights reserved.
//

import Foundation

/** 记得添加 libz.tbd 否则会报错 */
open class ZipManager: NSObject {
    
    /** 读一个zip文件 */
    class func read(from zipPath: String) -> [String: Data] {
        let archive = try! ZZArchive.init(url: URL.init(fileURLWithPath: zipPath))
        var dataDict = [String: Data]()
        for entry in archive.entries {
            let key = URL.init(fileURLWithPath: entry.fileName).lastPathComponent
            dataDict[key] = try! entry.newData()
        }
        return dataDict
    }
    
    /** 写入一个zip文件 */
    class func zipFile(from filePath: String, to zipPath: String) {

        let archive = try! ZZArchive.init(url: URL.init(fileURLWithPath: zipPath), options: [ZZOpenOptionsCreateIfMissingKey: true])
        let entry = ZZArchiveEntry.init(fileName: filePath, compress: true) { (error: NSErrorPointer) -> Data? in
            return "error".data(using: String.Encoding.utf8)
        }
        try! archive.updateEntries([entry])
    }
    
    /** 压缩一个文件夹下所有文件 */
    class func zipDirectory(from filePath: String, to zipPath: String) {
        let archive = try! ZZArchive.init(url: URL.init(fileURLWithPath: zipPath), options: [ZZOpenOptionsCreateIfMissingKey: true])
        
        var entries = archive.entries
        let subPaths = FileManager.default.subpaths(atPath: filePath)!
        for p in subPaths {
            let templateName = URL.init(fileURLWithPath: filePath).lastPathComponent
            var path = filePath+p
            path = path.replacingOccurrences(of: "//", with: "/")
            let url = URL.init(fileURLWithPath: path)
            
            var isDirectory = ObjCBool.init(false)
            let isfileExist = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
            if isDirectory.boolValue == false {
                if isfileExist == true {
                    let fileEntry = ZZArchiveEntry.init(fileName: templateName+"/"+p, compress: true) { (error: NSErrorPointer) -> Data? in
                        let data = try! Data.init(contentsOf: url)
                        return data
                    }
                    entries.append(fileEntry)
                }
            } else {
                let directoryEntry = ZZArchiveEntry.init(directoryName: templateName+"/"+p+"/")
                entries.append(directoryEntry)
            }
        }
        try! archive.updateEntries(entries)
        try! FileManager.default.removeItem(atPath: filePath)
    }
    
    /** 追加到一个zip文件 */
    class func append(from filePath: String, to zipPath: String) {
        let archive = try! ZZArchive.init(url: URL.init(fileURLWithPath: zipPath))
        let entry = ZZArchiveEntry.init(fileName: filePath, compress: true) { (error: NSErrorPointer) -> Data? in
            return "error".data(using: String.Encoding.utf8)
        }
        var entries = archive.entries
        entries.append(entry)
        try! archive.updateEntries(entries)
    }
    
    /** 解压一个zip文件到目标文件夹 */
    class func unzip(from zipPath: String, to directory: String) {
        let archive = try! ZZArchive.init(url: URL.init(fileURLWithPath: zipPath))
        for entry in archive.entries {
            if entry.fileName.hasSuffix("/") == true {
                // 如果是目录，创建目录
                try! FileManager.default.createDirectory(atPath: directory+entry.fileName, withIntermediateDirectories: true, attributes: nil)
            } else {
                // 如果是文件，创建文件
                let data = try! entry.newData()
                try! data.write(to: URL.init(fileURLWithPath: directory+entry.fileName))
            }
        }
    }
}

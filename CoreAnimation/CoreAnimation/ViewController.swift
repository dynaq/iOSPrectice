//
//  ViewController.swift
//  CoreAnimation
//
//  Created by 石震宇 on 2021/4/14.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var table: UITableView!
    
    fileprivate let data = ["Rectangle", "Circle"]
    fileprivate let vcs = ["RectangleViewController", "CircleViewController"]
    override func viewDidLoad() {
        super.viewDidLoad()
        table.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "DataCellIdentifier")
        table.delegate = self
        table.dataSource = self
        // Do any additional setup after loading the view.
    }


}

extension ViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "DataCellIdentifier")
        cell.textLabel?.text = data[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let nameSpace = Bundle.main.infoDictionary!["CFBundleExecutable"] as? String else{
            return
        }
        let name = vcs[indexPath.row]
        guard let vc = NSClassFromString(nameSpace + "." + name) as? UIViewController.Type else{
            return
        }
        self.navigationController?.pushViewController(vc.init(), animated: true)
    }
}

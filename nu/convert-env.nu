use std/dirs

def main [] {
    dirs add "../secrets"
    mkdir env
    ls ./templates/*.template.env | each {|file| process-file $file}
    dirs drop    
    print "Готово"
}

def process-file [file: record<name: string, type: string, size: filesize, modified: datetime>] {
    try {
        let NewName = $"($file.name | parse "templates\\{name}.template.env" | get name.0).env"
        let NewFilePath = $"./env/($NewName)"
        if not ($NewFilePath | path exists) {
            cp -n $file.name $NewFilePath
            print $"($NewName) (ansi green)created(ansi reset)"
        } else {
            print $"($NewName) (ansi y)already exists(ansi reset)"
        }
    } catch {
        |err|
        print $"(ansi r)ERROR: ($err)(ansi reset)" 
    } 
}
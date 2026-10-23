import Foundation
import Darwin

public final class ProcessLock {
    private var descriptor:Int32 = -1
    public init(file:URL) throws {
        try FileManager.default.createDirectory(at:file.deletingLastPathComponent(),withIntermediateDirectories:true,attributes:[.posixPermissions:0o700])
        let fd=open(file.path,O_RDWR|O_CREAT|O_NOFOLLOW,0o600)
        guard fd >= 0 else { throw HarborError.invalid("Não foi possível abrir o controle de instância do aplicativo.") }
        guard flock(fd,LOCK_EX|LOCK_NB)==0 else { close(fd);throw HarborError.invalid("Outra instância do WorkHarbor já está usando estes dados.") }
        descriptor=fd
    }
    deinit { if descriptor>=0 { flock(descriptor,LOCK_UN);close(descriptor) } }
}

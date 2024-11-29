package com.example.sshtool

import android.util.Log
import com.jcraft.jsch.Channel
import com.jcraft.jsch.ChannelShell
import com.jcraft.jsch.JSch
import com.jcraft.jsch.JSchException
import com.jcraft.jsch.Session

class SSHManager {
    private val jsch = JSch()
    private var session: Session? = null
    private var channel: Channel? = null
    
    fun connect(host: String, username: String, password: String, port: Int): Boolean {
        return try {
            session = jsch.getSession(username, host, port).apply {
                setPassword(password)
                setConfig("StrictHostKeyChecking", "no")
                timeout = 10000
                setConfig("connectTimeout", "10000")
                connect()
            }
            true
        } catch (e: JSchException) {
            Log.e("SSHManager", "连接失败", e)
            false
        }
    }
    
    fun openShell(): ChannelShell {
        return (session?.openChannel("shell") as? ChannelShell)?.apply {
            setPtyType("xterm")
            setPty(true)
            connect(3000)
        } ?: throw JSchException("无法创建 Shell 通道")
    }
    
    fun disconnect() {
        session?.disconnect()
    }
} 
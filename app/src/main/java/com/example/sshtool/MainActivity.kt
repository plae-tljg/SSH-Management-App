package com.example.sshtool

import android.os.Bundle
import android.view.KeyEvent
import android.view.inputmethod.EditorInfo
import android.widget.ScrollView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.sshtool.databinding.ActivityMainBinding
import com.jcraft.jsch.JSchException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.IOException
import com.example.sshtool.SSHManager
import android.util.Log
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.content.Context

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding
    private lateinit var sshManager: SSHManager
    private val scope = CoroutineScope(Dispatchers.Main + Job())
    private val TAG = "SSHTool"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            binding = ActivityMainBinding.inflate(layoutInflater)
            setContentView(binding.root)

            setDefaultCredentials()

            sshManager = SSHManager()
            setupClickListeners()
            
            Log.d(TAG, "设置默认值 - Host: ${binding.hostInput.text}")
            Log.d(TAG, "设置默认值 - Username: ${binding.usernameInput.text}")
        } catch (e: Exception) {
            Log.e(TAG, "初始化失败", e)
            Toast.makeText(this, "初始化失败: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    private fun setDefaultCredentials() {
        binding.hostInput.apply {
            setText(Constants.DEFAULT_SSH_HOST)
            hint = "SSH 主机地址"
        }
        
        binding.usernameInput.apply {
            setText(Constants.DEFAULT_SSH_USERNAME)
            hint = "用户名"
        }
        
        binding.passwordInput.apply {
            setText(Constants.DEFAULT_SSH_PASSWORD)
            hint = "密码"
        }
    }

    private fun setupClickListeners() {
        binding.connectButton.setOnClickListener {
            connectToServer()
        }
    }

    private fun checkNetworkConnection(): Boolean {
        val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = connectivityManager.activeNetwork
        val capabilities = connectivityManager.getNetworkCapabilities(network)
        
        return if (capabilities != null) {
            when {
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> {
                    Log.d(TAG, "网络连接: WiFi")
                    true
                }
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> {
                    Log.d(TAG, "网络连接: 移动数据")
                    true
                }
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> {
                    Log.d(TAG, "网络连接: 以太网")
                    true
                }
                else -> {
                    Log.d(TAG, "无可用网络连接")
                    false
                }
            }
        } else {
            Log.d(TAG, "网络连接: 无网络")
            false
        }
    }

    private fun connectToServer() {
        if (!checkNetworkConnection()) {
            Toast.makeText(this, "请检查网络连接", Toast.LENGTH_SHORT).show()
            return
        }

        val host = binding.hostInput.text.toString()
        val username = binding.usernameInput.text.toString()
        val password = binding.passwordInput.text.toString()

        Log.d(TAG, "正在尝试连接到: $host")
        
        scope.launch(Dispatchers.IO) {
            try {
                val connected = sshManager.connect(host, username, password, 22)
                withContext(Dispatchers.Main) {
                    if (connected) {
                        Toast.makeText(this@MainActivity, "连接成功！", Toast.LENGTH_SHORT).show()
                        startShell()
                    } else {
                        Toast.makeText(this@MainActivity, "连接失败！", Toast.LENGTH_SHORT).show()
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "连接异常", e)
                withContext(Dispatchers.Main) {
                    Toast.makeText(
                        this@MainActivity,
                        "连接错误: ${e.message}",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
        }
    }

    private fun startShell() {
        scope.launch(Dispatchers.IO) {
            try {
                Log.d(TAG, "正在打开 Shell 通道")
                val channelShell = sshManager.openShell()
                val inputStream = channelShell.inputStream
                val outputStream = channelShell.outputStream
                Log.d(TAG, "Shell 通道已打开")

                // 创建读取线程
                Thread {
                    val buffer = ByteArray(1024)
                    var bytesRead: Int
                    try {
                        while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                            val output = String(buffer, 0, bytesRead)
                            Log.d(TAG, "收到输出: $output")
                            runOnUiThread {
                                binding.terminalOutput.append(output)
                                binding.terminalOutput.parent.requestLayout()
                                (binding.terminalOutput.parent as ScrollView).fullScroll(ScrollView.FOCUS_DOWN)
                            }
                        }
                    } catch (e: IOException) {
                        Log.e(TAG, "读取输出流失败", e)
                        e.printStackTrace()
                    }
                }.start()

                // 设置命令输入监听
                withContext(Dispatchers.Main) {
                    binding.commandInput.setOnEditorActionListener { _, actionId, event ->
                        if (actionId == EditorInfo.IME_ACTION_SEND ||
                            (event?.keyCode == KeyEvent.KEYCODE_ENTER && event.action == KeyEvent.ACTION_DOWN)
                        ) {
                            val command = binding.commandInput.text.toString() + "\n"
                            Log.d(TAG, "准备发送命令: $command")
                            scope.launch(Dispatchers.IO) {
                                try {
                                    outputStream.write(command.toByteArray())
                                    outputStream.flush()
                                    Log.d(TAG, "命令发送成功")
                                    withContext(Dispatchers.Main) {
                                        binding.commandInput.text?.clear()
                                    }
                                } catch (e: IOException) {
                                    Log.e(TAG, "发送命令失败", e)
                                    e.printStackTrace()
                                    withContext(Dispatchers.Main) {
                                        Toast.makeText(
                                            this@MainActivity,
                                            "发送命令失败: ${e.message}",
                                            Toast.LENGTH_SHORT
                                        ).show()
                                    }
                                }
                            }
                            true
                        } else {
                            false
                        }
                    }

                    // 添加发送按钮点击监听
                    binding.commandInput.setOnKeyListener { _, keyCode, event ->
                        if (event.action == KeyEvent.ACTION_DOWN && keyCode == KeyEvent.KEYCODE_ENTER) {
                            val command = binding.commandInput.text.toString() + "\n"
                            scope.launch(Dispatchers.IO) {
                                try {
                                    outputStream.write(command.toByteArray())
                                    outputStream.flush()
                                    withContext(Dispatchers.Main) {
                                        binding.commandInput.text?.clear()
                                    }
                                } catch (e: IOException) {
                                    e.printStackTrace()
                                    withContext(Dispatchers.Main) {
                                        Toast.makeText(
                                            this@MainActivity,
                                            "发送命令失败: ${e.message}",
                                            Toast.LENGTH_SHORT
                                        ).show()
                                    }
                                }
                            }
                            true
                        } else {
                            false
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Shell 启动失败", e)
                withContext(Dispatchers.Main) {
                    Toast.makeText(this@MainActivity, "Shell 启动失败：${e.message}", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    override fun onDestroy() {
        scope.cancel()
        sshManager.disconnect()
        super.onDestroy()
    }
}
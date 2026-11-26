package com.hiennv.flutter_callkit_incoming

import android.annotation.SuppressLint
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import androidx.core.content.ContextCompat

class CallkitNotificationService : Service() {

    companion object {

        private val ActionForeground = listOf(
            CallkitConstants.ACTION_CALL_START,
            CallkitConstants.ACTION_CALL_ACCEPT
        )


        fun startServiceWithAction(context: Context, action: String, data: Bundle?) {
            val intent = Intent(context, CallkitNotificationService::class.java).apply {
                this.action = action
                putExtra(CallkitConstants.EXTRA_CALLKIT_INCOMING_DATA, data)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && intent.action in ActionForeground) {
                data?.let {
                    if(it.getBoolean(CallkitConstants.EXTRA_CALLKIT_CALLING_SHOW, true)) {
                        ContextCompat.startForegroundService(context, intent)
                    }else {
                        context.startService(intent)
                    }
                }
            } else {
                context.startService(intent)
            }
        }

        fun stopService(context: Context) {
            val intent = Intent(context, CallkitNotificationService::class.java)
            context.stopService(intent)
        }

    }

    private val callkitNotificationManager: CallkitNotificationManager? =
        FlutterCallkitIncomingPlugin.getInstance()?.getCallkitNotificationManager()


    override fun onCreate() {
        super.onCreate()
    }

    // YAMA: action karsilastirmasi `===` (referans) yerine `==`; Intent
    // parcel'laninca string ayni nesne olmayabilir.
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == CallkitConstants.ACTION_CALL_START) {
            intent.getBundleExtra(CallkitConstants.EXTRA_CALLKIT_INCOMING_DATA)
                ?.let {
                    if(it.getBoolean(CallkitConstants.EXTRA_CALLKIT_CALLING_SHOW, true)) {
                        FlutterCallkitIncomingPlugin.getInstance()?.getCallkitNotificationManager()
                            ?.createNotificationChanel(it)
                        showOngoingCallNotification(it, false)
                    }else {
                        stopSelf()
                    }
                }
        }
        if (intent?.action == CallkitConstants.ACTION_CALL_ACCEPT) {
            intent.getBundleExtra(CallkitConstants.EXTRA_CALLKIT_INCOMING_DATA)
                ?.let {
                    callkitNotificationManager?.clearIncomingNotification(it, true)
                    if (it.getBoolean(CallkitConstants.EXTRA_CALLKIT_CALLING_SHOW, true)) {
                        showOngoingCallNotification(it, false)
                    }else {
                        stopSelf()
                    }
                }
        }
        // YAMA: gorusme baglaninca (uygulama genelde on planda) servisi
        // mikrofon tipiyle yeniden on plana al; arka planda kabul edilen
        // cagride ilk baslangicta mikrofon tipi reddedilmis olabilir.
        if (intent?.action == CallkitConstants.ACTION_CALL_CONNECTED) {
            intent.getBundleExtra(CallkitConstants.EXTRA_CALLKIT_INCOMING_DATA)
                ?.let {
                    if (it.getBoolean(CallkitConstants.EXTRA_CALLKIT_CALLING_SHOW, true)) {
                        showOngoingCallNotification(it, true)
                    }
                }
        }
        return START_STICKY
    }

    @SuppressLint("MissingPermission")
    private fun showOngoingCallNotification(bundle: Bundle, isConnected: Boolean) {

        val callkitNotification =
            this.callkitNotificationManager?.getOnGoingCallNotification(bundle, isConnected)
        if (callkitNotification != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && mikrofonIzniVar()) {
                // YAMA: VoIP gorusmesinde uygulama arka plana gecince Android
                // mikrofonu ancak microphone tipli on plan servisiyle verir.
                // Arka plandan baslatma reddedilirse phoneCall ile devam.
                try {
                    startForeground(
                        callkitNotification.id,
                        callkitNotification.notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL or
                            ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                    )
                    return
                } catch (e: Exception) {
                    android.util.Log.w("CallkitNotifService", "microphone FGS reddedildi: $e")
                }
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    callkitNotification.id,
                    callkitNotification.notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL
                )
            } else {
                startForeground(callkitNotification.id, callkitNotification.notification)
            }
        }
    }

    private fun mikrofonIzniVar(): Boolean =
        ContextCompat.checkSelfPermission(this, android.Manifest.permission.RECORD_AUDIO) ==
            android.content.pm.PackageManager.PERMISSION_GRANTED


    override fun onDestroy() {
        super.onDestroy()
        callkitNotificationManager?.destroy()
    }

    override fun onBind(p0: Intent?): IBinder? {
        return null
    }


    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        }else {
            stopForeground(true)
        }
        stopSelf()
    }



}


package com.example.mainapp;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;



import android.media.MediaRecorder;
import android.os.Build;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

// class Recorder{
//     private boolean isRecording = false;
//     // private boolean 
//     private MediaRecorder recMR = null;
    
// }
public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "samples.flutter.dev/recordingaudio";

    // private boolean isRecording = false;
    // private boolean 
    private MediaRecorder recMR = null;
    public void startTheRec(){
        recMR = new MediaRecorder();
        recMR.setAudioSource(MediaRecorder.AudioSource.MIC);
        recMR.setAudioEncodingBitRate(128000);
        recMR.setAudioSamplingRate(44100);
        recMR.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4);
        recMR.setAudioEncoder(MediaRecorder.AudioEncoder.AAC_ELD);
        // recMR.setOutputFile("/storage/emulated/0/Android/data/com.example.mainapp/files/bruh.mp3");
        recMR.setOutputFile("/dev/null");
        
        try {
            recMR.prepare();
            recMR.start();    
        } catch (Exception e) {
            //TODO: handle exception
            System.out.println("couldnt start the recording");
            System.out.println(e.getMessage());
        }
    }

    public void stopTheRec(){
        if (recMR != null) {
            recMR.stop();       
            recMR.release();
            recMR = null;
        }
    }

    public int getAmplitude() {
        if (recMR != null)
            return  recMR.getMaxAmplitude();
        else
            return 0;

    }

 @Override
 public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
 GeneratedPluginRegistrant.registerWith(flutterEngine);
 new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
 .setMethodCallHandler(
   (call, result) -> {
     if(call.method.equals("getVolume")){
        // System.out.println("Inside getVolume from Channel");
        int theVol = getAmplitude();
        if (theVol >= 0) {
            double dbVol = (20 * Math.log10(theVol));
            // result.success(theVol);
            result.success(dbVol);
          } else {
            result.error("UNAVAILABLE", "Sound level not available.", null);
          }
     }
     else if(call.method.equals("startREC")){
        System.out.println("Inside startREC from Channel");
        startTheRec();
        result.success(null);
     }
     else if(call.method.equals("stopREC")){
         stopTheRec();
         result.success(null);
     }
     else{
        result.notImplemented();

     }
   }
 );
 }
}
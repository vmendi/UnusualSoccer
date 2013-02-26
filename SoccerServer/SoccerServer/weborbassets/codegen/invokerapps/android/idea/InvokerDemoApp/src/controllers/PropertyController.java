package controllers;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import com.example.R;
import models.AppModel;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;

/**
 * Property controller. Manages connection properties.
 *
 * @author Yuri Samsoniuk
 */
public class PropertyController {
    /**
     * Main activity for property window
     */
    private Activity activity;
    /**
     * Main model for working with properties
     */
    AppModel model = AppModel.getInstance();

    /**
     * Connection test result states
     */
    private final int CONNECTION_SUCCESS = 0;
    private final int CONNECTION_FAILED = 1;
    /**
     * Connection test result dialog's titles
     */
    private final String[] dialog_titles;
    /**
     * Connection test result dialog's messages
     */
    private final String[] dialog_messages;

    /**
     * Main constructor
     *
     * @param activity main activity for property window
     */
    public PropertyController(Activity activity) {
        this.activity = activity;
        dialog_titles = activity.getResources().getStringArray(R.array.connection_dialog_titles);
        dialog_messages = activity.getResources().getStringArray(R.array.connection_dialog_messages);
    }

    /**
     * Test for success connection using passed URL
     *
     * @param weborbUrl WebORB Endpoint URL
     */
    public void testConnection(String weborbUrl) {
        try {
            URL url = new URL(weborbUrl);
            HttpURLConnection urlConnection = (HttpURLConnection) url.openConnection();
            urlConnection.setRequestMethod("GET");
            urlConnection.setConnectTimeout(1000);
            urlConnection.connect();
            int responseCode = urlConnection.getResponseCode();
            // check if response code in range of success http response codes
            if (responseCode >= 200 && responseCode <= 226) {
                showConnectionTestDialog(CONNECTION_SUCCESS);
            } else {
                showConnectionTestDialog(CONNECTION_FAILED);
            }
//        } catch (MalformedURLException e) {
//            e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
//        } catch (ProtocolException e) {
//            e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
        } catch (IOException e) {
            e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
            showConnectionTestDialog(CONNECTION_FAILED);
        }
    }

    /**
     * Accepts new connection properties
     *
     * @param weborbUrl WebOrb URL to set connection property
     */
    public void accept(String weborbUrl) {
        model.WebORBURL = weborbUrl;
        model.saveProperties();
        activity.finish();
    }

    /**
     * Returns WebORB Endpoint URL
     *
     * @return WebORB Endpoint URL
     */
    public String getWebORBURL() {
        return model.WebORBURL;
    }

    /**
     * Shows dialog about connection test result
     *
     * @param dialogMode connection test result state
     */
    private void showConnectionTestDialog(int dialogMode) {
        AlertDialog.Builder builder = new AlertDialog.Builder(activity);
        builder.setTitle(dialog_titles[dialogMode]);
        switch (dialogMode) {
            case CONNECTION_SUCCESS:
                builder.setIcon(android.R.drawable.ic_dialog_info);
                break;
            case CONNECTION_FAILED:
                builder.setIcon(android.R.drawable.ic_dialog_alert);
                break;
        }
        builder.setMessage(dialog_messages[dialogMode]);
        builder.setPositiveButton("Ok", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialogInterface, int i) {
                dialogInterface.dismiss();
            }
        });
        builder.show();
    }
}

package controllers;

import android.app.Activity;
import android.content.Intent;
import android.view.View;
import android.widget.SimpleAdapter;
import android.widget.TextView;
import com.example.MethodView;
import com.example.PropertyView;
import com.example.R;
import models.AppModel;

import java.util.ArrayList;
import java.util.Map;

/**
 * Method list controller. Manages methods and their signatures, invoking new controller for method invocation process.
 * @author Yuri Samsoniuk
 */
public class MethodListController {
    /**
     * Keys for methods description filling
     */
    private final String METHOD_NAME = "method_name";
    private final String METHOD_DESCRIPTION = "method_description";

    /**
     * Activity for method list display
     */
    private Activity activity;
    /**
     * Managing methods model
     */
    private AppModel model;

    /**
     * Controller main constructor
     * @param activity activity for method list display
     */
    public MethodListController(Activity activity) {
        this.activity = activity;
        model = AppModel.getInstance();
    }

    /**
     * Returns adapter for filling methods list
     * @return adapter containing method description list
     */
    public SimpleAdapter getListEvent() {
        ArrayList<Map<String, String>> methodsDescriptionList
                = (ArrayList<Map<String, String>>) model.getMethodDescriptionList(METHOD_NAME, METHOD_DESCRIPTION);
        return new SimpleAdapter(activity, methodsDescriptionList, R.layout.methods_list_item_view,
                new String[]{METHOD_NAME, METHOD_DESCRIPTION}, new int[]{R.id.method_name, R.id.method_description});
    }

    /**
     * Manages click on method list item
     * @param position position of the clicked item in the list
     */
    public void itemClickedEvent(int position) {
        model.setCurrentMethod(position);
        Intent intent = new Intent(activity, MethodView.class);
        activity.startActivity(intent);
    }

    /**
     * Returns header view for method views list
     * @return haader view
     */
    public View getHeaderView() {
        TextView view = new TextView(activity);
        view.setTextAppearance(activity, android.R.style.TextAppearance_Medium);
        view.setPadding(5, 5, 5, 5);
        view.setText("Methods for: " + model.invokingServiceClass);
        return view;
    }

    /**
     * Manages click on menu item
     */
    public void configureConnectionsRequest() {
        Intent intent = new Intent(activity, PropertyView.class);
        activity.startActivity(intent);
    }
}

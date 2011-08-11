package models;

import android.app.Activity;
import android.text.InputType;
import android.view.View;
import android.widget.TextView;import com.example.R;import controllers.AbstractController;

import java.lang.reflect.Type;
import java.text.ParseException;
import java.util.ArrayList;

/**
 * Abstract model of the arguments
 * @author Yuri Samsoniuk
 */
public abstract class ArgInfo {
    /**
     * Main view of the model
     */
    protected View view;
    /**
     * Model subviews
     */
    protected ArrayList<View> views;
    /**
     * Application activity
     */
    protected Activity activity;
    /**
     * Handling controller
     */
    protected AbstractController controller;
    /**
     * Padding of the main view
     */
    protected int padding;
    /**
     * Object value of the data of the model
     */
    protected Object value;
    /**
     * Type of data represented by the model
     */
    protected Type type;

    /**
     * Constructor of the model
     * @param type of data represented by the model
     * @param activity  application activity
     * @param controller handling controller
     * @param padding padding of the main view
     */
    public ArgInfo(Type type, Activity activity, AbstractController controller, int padding) {
        this.type = type;
        this.activity = activity;
        this.controller = controller;
        this.padding = padding;
        views = new ArrayList<View>();
    }

    /**
     * Create main view with specified name
     * @param name name of the main view
     */
    public abstract void createView(String name);

    /**
     * Returns main view
     * @return main view
     */
    public View getMainView() {
        return view;
    }

    /**
     * Returns subviews of the passed view
     * @param view view to search subviews for
     * @return if view is a part of model views then subviews of the passed view, else return <code>null</code>
     */
    public ArrayList<View> getSubViews(View view) {
        return null;
    }

    /**
     * Add new view to specified view represented by model
     * @param view view of the model to add view on
     * @return if passed view corresponds to model, then return new view, else <code>null<code>
     */
    public View addView(View view) {
        return null;
    }

    /**
     * Returns position of passed view in the model
     * @param view view to get position of
     * @return if passed view is one of view of the model, then return position, else -1
     */
    public int getPosition(View view) {
        if(view == this.view) {
            return 0;
        }
        return -1;
    }

    /**
     * Returns number of rows taken by the model
     * @return number of rows
     */
    public int getRowsCount() {
        return 1;
    }

    /**
     * Returns data value of the model
     * @return data value
     * @throws ParseException if data in the view is unparsable to model type
     */
    public abstract Object getValue() throws ParseException;

    /**
     * Sets the value of the model in the main view and subviews
     * @param value object value to set data from
     */
    public abstract void setValue(Object value);

    /**
     * Returns input type for input data dialog
     * @param view view to input data for
     * @return input type
     */
    public int getInputType(View view) {
        return InputType.TYPE_NULL;
    }

    /**
     * Returns model class that handles passed view as main one
     * @param   view view of the model
     * @return  if passed view is main view of the model or sub models
     *          then return appropriate model class, else return <code>null</code>
     */
    public Class getModelClass(View view) {
        return view == this.view ? this.getClass() : null;
    }

    /**
     * Returns <code>String</code> data value of the model
     * @return <code>String</code> data value
     */
    public String getStringValue() {
        return ((TextView) view.findViewById(R.id.value)).getText().toString();
    }
}

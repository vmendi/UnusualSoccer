package controllers;

import android.app.Activity;
import android.view.View;
import models.*;

import java.lang.reflect.ParameterizedType;
import java.lang.reflect.Type;
import java.util.*;

/**
 * Abstract controller class for managing models and their representing views.
 *
 * @author Yuri Samsoniuk
 */
public abstract class AbstractController {
    /**
     * Main activity for main window showing
     */
    protected Activity activity;
    /**
     * Default padding of the main level model's views
     */
    protected final int defaultPadding = 5;

    /**
     * Controller main constructor
     *
     * @param activity main activity for main window showing
     */
    public AbstractController(Activity activity) {
        this.activity = activity;
    }

    /**
     * Returns model object according to passed type. Sets padding of the model view to specified padding
     *
     * @param padding model view padding
     * @param type    type of data for model
     * @return new model instance
     */
    public ArgInfo getModel(int padding, Type type) {
        ArgInfo model;
        if (type instanceof ParameterizedType) {
            if (Map.class.isAssignableFrom((Class<?>) ((ParameterizedType) type).getRawType())) {
                model = new MapArgInfo(type, activity, this, padding);
            } else {
                model = new GenericArgInfo(type, activity, this, padding);
            }
        } else if (Map.class.isAssignableFrom((Class<?>) type)) {
            model = new MapArgInfo(type, activity, this, padding);
        } else if (Date.class.isAssignableFrom((Class<?>) type)) {
            model = new DateArgInfo(type, activity, this, padding);
        } else if ((((Class<?>) type).isArray() && !Character.TYPE.isAssignableFrom(((Class<?>) type).getComponentType()))
                || List.class.isAssignableFrom((Class<?>) type)
                || Set.class.isAssignableFrom((Class<?>) type)) {
            model = new ArrayArgInfo(type, activity, this, padding);
        } else if (Boolean.class.isAssignableFrom((Class<?>) type) || Boolean.TYPE.isAssignableFrom((Class<?>) type)) {
            model = new BooleanArgInfo(type, activity, this, padding);
        } else if (((Class<?>) type).isEnum()) {
            model = new EnumArgInfo(type, activity, this, padding);
        } else if (!CharSequence.class.isAssignableFrom((Class<?>) type) && !((Class<?>) type).isArray()
                && !Number.class.isAssignableFrom((Class<?>) type) && !((Class<?>) type).isPrimitive()) {
            model = new ComplexTypeArgInfo(type, activity, this, padding);
        } else {
            model = new PrimitiveArgInfo(type, activity, this, padding);
        }
        return model;
    }

    /**
     * Adds new items for model containing passed views.
     * Have to be overrided in subclasses
     *
     * @param views to add. First one is the main view
     */
    public void addItems(View... views) {
    }

    /**
     * Returns listener taken from activity for view.
     * Have to overrided in subclases.
     *
     * @return listener for managing on view click
     */
    public View.OnClickListener getListener() {
        return null;
    }

    /**
     * Returns list of all views of the main models.
     *
     * @return list of views to be shown
     */
    public abstract ArrayList<View> getViewList();

    /**
     * Returns title for main window.
     *
     * @return main window title
     */
    public abstract String getTitle();
}

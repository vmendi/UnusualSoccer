package controllers;

import android.app.Activity;
import android.view.View;
import com.example.R;
import models.*;

import java.lang.reflect.Type;
import java.util.ArrayList;

/**
 * Controller class for managing models and their representing views.
 * Manages result data display
 * @author Yuri Samsoniuk
 */
public class ResultController extends AbstractController {
    /**
     * Result type
     */
    private Type resultType;
    /**
     * Result object
     */
    private Object result;
    /**
     * Model for result object
     */
    private ArgInfo model;
    /**
     * Model main view
     */
    private View mainView;
    /**
     * Controller main constructor
     * @param activity main activity for main window showing
     */
    public ResultController(Activity activity) {
        super(activity);
        result = AppModel.getInstance().methodInvokationResult;
        resultType = AppModel.getInstance().methodInvokationResultType;
        inspectResult();
    }

    /**
     * Inspects result and creates its model
     */
    private void inspectResult() {
        model = getModel(defaultPadding, resultType);
        model.createView("result");
        model.setValue(result);
    }

    @Override
    public String getTitle() {
        return activity.getResources().getString(R.string.result_view_title);
    }

    @Override
    public ArrayList<View> getViewList() {
        ArrayList<View> views = new ArrayList<View>();
        mainView = model.getMainView();
        views.add(mainView);
        ArrayList<View> subViews = model.getSubViews(mainView);
        if (subViews != null) {
            views.addAll(subViews);
        }
        return views;
    }
}

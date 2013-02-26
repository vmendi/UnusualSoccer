package controllers;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Handler;
import android.os.Message;
import android.text.InputType;
import android.view.View;
import com.example.MethodView;
import com.example.R;
import com.example.ResultView;
import models.*;
import weborb.client.Fault;
import weborb.client.IResponder;
import weborb.exceptions.MessageException;

import java.lang.reflect.*;
import java.text.ParseException;
import java.util.*;

/**
 * Controller class for managing models and their representing views.
 * Manages data input and invoking method period.
 *
 * @author Yuri Samsoniuk
 */
public class MethodController extends AbstractController {
    /**
     * Models for method arguments
     */
    private List<ArgInfo> models;
    /**
     * Invoking method
     */
    private Method method;

    /**
     * Dialog Ids. Main view(activity) use them for managing dialogs of data input.
     */
    public static final int PRIMITIVE_TYPE_DIALOG_ID = 0;
    public static final int DATE_DIALOG_ID = 1;
    public static final int BOOLEAN_DIALOG_ID = -1;

    /**
     * Progress dialog for displaying process while invocation.
     */
    private ProgressDialog progressDialog;
    /**
     * Responder on invocation
     */
    private IResponder responder = new IResponder() {
        public void responseHandler(Object o) throws MessageException {
            AppModel.getInstance().methodInvokationResult = ((Object[]) o)[0];
            AppModel.getInstance().errorMessage = null;
        }

        public void errorHandler(Fault fault) throws MessageException {
            AppModel.getInstance().methodInvokationResult = null;
            AppModel.getInstance().errorMessage = fault.getDetail();
        }
    };
    /**
     * Invocation handler manages process of collection data and invocation for result
     */
    private final Handler invokationHandler = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            int mState = msg.arg1;
            switch (mState) {
                case InvokingThread.INVOKE_SUCCESS:
                    Intent intent = new Intent(activity, ResultView.class);
                    activity.startActivity(intent);
                    progressDialog.dismiss();
                    break;
                case InvokingThread.INVOKE_FAILED:
                    showErrorDialog(AppModel.getInstance().errorMessage);
                    progressDialog.dismiss();
                    break;
                case InvokingThread.DATA_COLLECT_SUCCESS:
                    progressDialog.setMessage(activity.getResources().getString(R.string.progress_dialog_invoking));
                    break;
                case InvokingThread.DATA_COLLECT_FAILED:
                    showErrorDialog(AppModel.getInstance().errorMessage);
                    progressDialog.dismiss();
                    break;
            }
        }
    };

    /**
     * Controller main constructor
     *
     * @param activity main activity for main window showing
     */
    public MethodController(Activity activity) {
        super(activity);
        method = AppModel.getInstance().currentMethod;
        models = new ArrayList<ArgInfo>();
        inspectMethod();
    }

    /**
     * Inspects method and creates model for method arguments.
     */
    private void inspectMethod() {
        Type[] argumentTypes = method.getGenericParameterTypes();
        for (int i = 0; i < argumentTypes.length - 1; i++) {
            ArgInfo model = getModel(defaultPadding, argumentTypes[i]);
            models.add(model);
        }
    }

    /**
     * Returns method signature.
     *
     * @return method signature string.
     */
    public String getMethodSignature() {
        String signature = method.getReturnType().getSimpleName() + " " + method.getName() + "(";
        Class[] parameterTypes = method.getParameterTypes();
        for (int i = 0; i < parameterTypes.length - 1; i++) {
            if (i == 0)
                signature += (parameterTypes[i].getSimpleName() + " arg" + i);
            else
                signature += (", " + parameterTypes[i].getSimpleName() + " arg" + i);
        }
        signature += ")";
        return signature;
    }

    @Override
    public ArrayList<View> getViewList() {
        ArrayList<View> allViews = new ArrayList<View>();
        for (int i = 0; i < models.size(); i++) {
            ArgInfo model = models.get(i);
            String name = "arg" + i;
            model.createView(name);
            View modelMainView = model.getMainView();
            ArrayList<View> modelSubViews = model.getSubViews(modelMainView);
            allViews.add(modelMainView);
            if (modelSubViews != null) {
                allViews.addAll(modelSubViews);
            }
        }
        return allViews;
    }

    @Override
    public void addItems(View... views) {
        int rowsBeforeView = 0;
        int position;
        View mainView = views[0];
        for (ArgInfo subModel : models) {
            if ((position = subModel.getPosition(mainView)) != -1) {
                position += rowsBeforeView;
                ((MethodView) activity).addView(position, views);
                return;
            } else {
                rowsBeforeView += subModel.getRowsCount();
            }
        }
    }

    /**
     * Returns input type for dialog of data input for passed view
     *
     * @param view view to get input type for
     * @return input type
     */
    public int getInputType(View view) {
        int position;
        for (ArgInfo model : models) {
            position = model.getPosition(view);
            if (position != -1) {
                return model.getInputType(view);
            }
        }
        return InputType.TYPE_NULL;
    }

    /**
     * Manages reaction on event for starting method invocation.
     */
    public void onMethodInvoke() {
        progressDialog = new ProgressDialog(activity);
        progressDialog.setMessage(activity.getResources().getString(R.string.progress_dialog_collection_data));
        progressDialog.setCancelable(false);
        progressDialog.show();
        new InvokingThread(invokationHandler).start();
    }

    /**
     * Manages reaction on cancel method preparing for invocation.
     */
    public void cancelMethod() {
        activity.finish();
    }

    /**
     * Shows error dialog for illegal data.
     *
     * @param errorMessage error message for dialog
     */
    private void showErrorDialog(String errorMessage) {
        AlertDialog.Builder builder = new AlertDialog.Builder(activity);
        builder.setTitle(R.string.error_dialog_title);
        builder.setIcon(android.R.drawable.ic_dialog_alert);
        builder.setMessage(errorMessage);
        builder.setPositiveButton("Ok", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialogInterface, int i) {
                dialogInterface.dismiss();
            }
        });
        builder.show();
    }

    @Override
    public String getTitle() {
        return method.getName();
    }

    /**
     * Returns input data dialog id for passed view.
     *
     * @param view view to get dialog id for.
     * @return dialog id
     */
    public int getDialogId(View view) {
        Class clazz = null;
        for (ArgInfo model : models) {
            clazz = model.getModelClass(view);
            if (clazz != null) {
                if (clazz.isAssignableFrom(DateArgInfo.class)) {
                    return DATE_DIALOG_ID;
                } else if (clazz.isAssignableFrom(BooleanArgInfo.class)) {
                    return BOOLEAN_DIALOG_ID;
                }
                break;
            }
        }
        return PRIMITIVE_TYPE_DIALOG_ID;
    }

    @Override
    public View.OnClickListener getListener() {
        return ((MethodView) activity).getListener();
    }

    /**
     * Invoking thread for processing data collecting and method invocation.
     */
    private class InvokingThread extends Thread {
        /**
         * Handler used for informing about thread progress
         */
        Handler mHandler;
        /**
         * Thread state ids.
         */
        public final static int DATA_COLLECT_SUCCESS = 0;
        public final static int DATA_COLLECT_FAILED = 1;
        public final static int INVOKE_SUCCESS = 2;
        public final static int INVOKE_FAILED = 3;

        /**
         * Thread constructor
         *
         * @param handler handler used for informing about thread progress
         */
        public InvokingThread(Handler handler) {
            mHandler = handler;
        }

        @Override
        public void run() {
            int state = collectArguments();
            Message msg = mHandler.obtainMessage();
            msg.arg1 = state;
            mHandler.sendMessage(msg);
            if (state == DATA_COLLECT_SUCCESS) {
                state = invokeMethod();
                msg = mHandler.obtainMessage();
                msg.arg1 = state;
                mHandler.sendMessage(msg);
            }
        }

        /**
         * Collects data from the model
         *
         * @return result state
         */
        private int collectArguments() {
            ArrayList<Object> argumentsList = new ArrayList<Object>();
            try {
                for (ArgInfo model : models) {
                    argumentsList.add(model.getValue());
                }
                argumentsList.add(responder);
            } catch (ParseException e) {
                AppModel.getInstance().errorMessage = e.toString();
                return DATA_COLLECT_FAILED;
            } catch (NumberFormatException e) {
                AppModel.getInstance().errorMessage = e.toString();
                return DATA_COLLECT_FAILED;
            } catch (IndexOutOfBoundsException e) {
                AppModel.getInstance().errorMessage = e.toString();
                return DATA_COLLECT_FAILED;
            }
            AppModel.getInstance().methodArguments = argumentsList.toArray();
            return DATA_COLLECT_SUCCESS;
        }

        /**
         * Invokes method with collected arguments
         *
         * @return result state
         */
        private int invokeMethod() {
            try {
                Object invokingClass = method.getDeclaringClass().getConstructor(String.class)
                        .newInstance(AppModel.getInstance().WebORBURL);
                method.invoke(invokingClass, AppModel.getInstance().methodArguments);
                if (AppModel.getInstance().methodInvokationResult != null
                        || AppModel.getInstance().errorMessage == null) {
                    AppModel.getInstance().methodInvokationResultType = AppModel.getInstance().methodInvokationResult.getClass();
                    return INVOKE_SUCCESS;
                }
            } catch (InstantiationException e) {
                AppModel.getInstance().errorMessage = e.toString();
            } catch (IllegalAccessException e) {
                AppModel.getInstance().errorMessage = e.toString();
            } catch (InvocationTargetException e) {
                AppModel.getInstance().errorMessage = e.toString();
            } catch (IllegalArgumentException e) {
                AppModel.getInstance().errorMessage = e.toString();
            } catch (NoSuchMethodException e) {
                AppModel.getInstance().errorMessage = e.toString();
            }
            return INVOKE_FAILED;
        }
    }
}

/*
 * Copyright (C) 2011 Brockmann Consult GmbH (info@brockmann-consult.de)
 * 
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 3 of the License, or (at your option)
 * any later version.
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, see http://www.gnu.org/licenses/
 */

package org.esa.snap.gui.preferences.layer;

import com.bc.ceres.binding.Property;
import com.bc.ceres.swing.TableLayout;
import com.bc.ceres.swing.binding.BindingContext;
import com.bc.ceres.swing.binding.PropertyEditorRegistry;
import org.esa.beam.glayer.NoDataLayerType;
import org.esa.snap.gui.preferences.ConfigProperty;
import org.esa.snap.gui.preferences.DefaultConfigController;
import org.esa.snap.gui.preferences.PreferenceUtils;
import org.netbeans.spi.options.OptionsPanelController;
import org.openide.util.HelpCtx;

import javax.swing.Box;
import javax.swing.JComponent;
import javax.swing.JPanel;
import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Insets;

/**
 * The first sub-panel of the layer preferences, handling general properties.
 *
 * @author thomas
 */
@org.openide.util.NbBundle.Messages({
        "Options_DisplayName_LayerNoData=No-Data Layer",
        "Options_Keywords_LayerNoData=layer, no-data"
})
@OptionsPanelController.SubRegistration(location = "LayerPreferences",
        displayName = "#Options_DisplayName_LayerNoData",
        keywords = "#Options_Keywords_LayerNoData",
        keywordsCategory = "Layer",
        id = "LayerNoData")
public final class NoDataPanel extends DefaultConfigController {

    /**
     * Preferences key for the no-data overlay color
     */
    public static final String PROPERTY_KEY_NO_DATA_OVERLAY_COLOR = "noDataOverlay.color";
    /**
     * Preferences key for the no-data overlay transparency
     */
    public static final String PROPERTY_KEY_NO_DATA_OVERLAY_TRANSPARENCY = "noDataOverlay.transparency";

    protected Object createBean() {
        return new NoDataBean();
    }

    @Override
    protected JPanel createPanel(BindingContext context) {
        TableLayout tableLayout = new TableLayout(2);
        tableLayout.setTableAnchor(TableLayout.Anchor.NORTHWEST);
        tableLayout.setTablePadding(new Insets(4, 10, 0, 0));
        tableLayout.setTableFill(TableLayout.Fill.BOTH);
        tableLayout.setColumnWeightX(1, 1.0);

        JPanel pageUI = new JPanel(tableLayout);

        PropertyEditorRegistry registry = PropertyEditorRegistry.getInstance();
        Property noDataOverlayColor = context.getPropertySet().getProperty(PROPERTY_KEY_NO_DATA_OVERLAY_COLOR);
        Property noDataOverlayTransparency = context.getPropertySet().getProperty(PROPERTY_KEY_NO_DATA_OVERLAY_TRANSPARENCY);

        JComponent[] noDataOverlayColorComponents = PreferenceUtils.createColorComponents(noDataOverlayColor);
        JComponent[] noDataOverlayTransparencyComponents = registry.findPropertyEditor(noDataOverlayTransparency.getDescriptor()).createComponents(noDataOverlayTransparency.getDescriptor(), context);

        pageUI.add(noDataOverlayColorComponents[0]);
        pageUI.add(noDataOverlayColorComponents[1]);
        pageUI.add(noDataOverlayTransparencyComponents[1]);
        pageUI.add(noDataOverlayTransparencyComponents[0]);
        pageUI.add(tableLayout.createVerticalSpacer());

        JPanel parent = new JPanel(new BorderLayout());
        parent.add(pageUI, BorderLayout.CENTER);
        parent.add(Box.createHorizontalStrut(100), BorderLayout.EAST);
        return parent;
    }

    @Override
    public HelpCtx getHelpCtx() {
        return new HelpCtx("layer");
    }

    @SuppressWarnings("UnusedDeclaration")
    static class NoDataBean {

        @ConfigProperty(label = "No-data overlay colour",
                key = PROPERTY_KEY_NO_DATA_OVERLAY_COLOR)
        Color noDataOverlayColor = NoDataLayerType.DEFAULT_COLOR;

        @ConfigProperty(label = "No-data overlay transparency",
                key = PROPERTY_KEY_NO_DATA_OVERLAY_TRANSPARENCY,
                interval = "[0.0,0.95]")
        double noDataOverlayTransparency = 0.3;
    }

}

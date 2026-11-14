.pragma library

function clearCrossSectionHover(root) {
    var candidate, i;
    root.crossDropHoverActive = false;

    var parentItem = root.parent;
    if (!parentItem || !parentItem.children) {
      return;
    }

    for (i = 0; i < parentItem.children.length; i++) {
      candidate = parentItem.children[i];
      if (!candidate || candidate.crossDropHoverActive === undefined)
        continue;
      candidate.crossDropHoverActive = false;
    }
}

function updateCrossSectionHover(root, globalX, globalY) {
    var area, candidate, i, localPoint, shouldHighlight;
    var parentItem = root.parent;
    if (!parentItem || !parentItem.children) {
      root.crossDropHoverActive = false;
      return;
    }

    root.crossDropHoverActive = false;

    for (i = 0; i < parentItem.children.length; i++) {
      candidate = parentItem.children[i];
      if (!candidate || candidate.sectionId === undefined || candidate.crossDropHoverActive === undefined) {
        continue;
      }

      shouldHighlight = false;
      if (candidate !== root && candidate.visible && candidate.enabled) {
        localPoint = candidate.mapFromGlobal(globalX, globalY);
        area = candidate.dropTargetArea ? candidate.dropTargetArea : candidate;
        shouldHighlight = localPoint.x >= area.x && localPoint.y >= area.y && localPoint.x <= area.x + area.width && localPoint.y <= area.y + area.height;
      }

      candidate.crossDropHoverActive = shouldHighlight;
    }
}

function findSectionAtGlobalPosition(root, globalX, globalY) {
    var area, candidate, i, localPoint;
    var parentItem = root.parent;
    if (!parentItem || !parentItem.children) {
      return "";
    }

    for (i = 0; i < parentItem.children.length; i++) {
      candidate = parentItem.children[i];
      if (!candidate || candidate === root) {
        continue;
      }

      // Only consider sibling section editors
      if (candidate.sectionId === undefined || !candidate.visible || !candidate.enabled) {
        continue;
      }

      localPoint = candidate.mapFromGlobal(globalX, globalY);
      area = candidate.dropTargetArea ? candidate.dropTargetArea : candidate;
      if (localPoint.x >= area.x && localPoint.y >= area.y && localPoint.x <= area.x + area.width && localPoint.y <= area.y + area.height) {
        return candidate.sectionId;
      }
    }

    return "";
}

function openWidgetSettings(root, component, overlayProvider, index, widgetData, Logger, readyStatus, errorStatus) {
    // Handle core widget settings
    {

      function instantiateAndOpen() {
        if (root._activeDialog) {
          try {
            root._activeDialog.close();
            root._activeDialog.destroy();
          } catch (e) {}
          root._activeDialog = null;
        }

        var dialog = component.createObject(overlayProvider(), {
                                              "widgetIndex": index,
                                              "widgetData": widgetData,
                                              "widgetId": widgetData.id,
                                              "sectionId": root.sectionId,
                                              "screen": root.screen,
                                              "barIsVertical": root.barIsVertical
                                            });

        if (dialog) {
          root._activeDialog = dialog;
          dialog.updateWidgetSettings.connect(root.updateWidgetSettings);
          dialog.closed.connect(() => {
                                  if (root._activeDialog === dialog) {
                                    root._activeDialog = null;
                                    dialog.destroy();
                                  }
                                });
          dialog.open();
        } else {
          Logger.e("NSectionEditor", "Failed to create settings dialog instance");
        }
      }

      if (component.status === readyStatus) {
        instantiateAndOpen();
      } else if (component.status === errorStatus) {
        Logger.e("NSectionEditor", component.errorString());
      } else {
        component.statusChanged.connect(function () {
          if (component.status === readyStatus) {
            instantiateAndOpen();
          } else if (component.status === errorStatus) {
            Logger.e("NSectionEditor", component.errorString());
          }
        });
      }
    }
}

function mapWidgetCoords(widget, widgetGrid) {
          return {
            x: widget.x + widgetGrid.x,
            y: widget.y + widgetGrid.y,
            width: widget.width,
            height: widget.height
          };
}

function updateDropIndicator(root, dragArea, widgetRepeater, widgetGrid, dropIndicator, pulseAnimation, mouseX, mouseY, marginXS, Qt) {
          var i;
          if (!dragArea.dragStarted || dragArea.draggedIndex === -1) {
            dropIndicator.opacity = 0;
            pulseAnimation.running = false;
            return;
          }

          let bestIndex = -1;
          let bestPosition = null;
          let minDistance = Infinity;

          // Check position relative to each widget
          for (i = 0; i < root.widgetModel.length; i++) {
            if (i === dragArea.draggedIndex)
              continue;
            const widget = widgetRepeater.itemAt(i);
            if (!widget || widget.widgetIndex === undefined)
              continue;

            const mapped = mapWidgetCoords(widget, widgetGrid);

            // Check distance to left edge (insert before)
            const leftDist = Math.sqrt(Math.pow(mouseX - mapped.x, 2) + Math.pow(mouseY - (mapped.y + mapped.height / 2), 2));

            // Check distance to right edge (insert after)
            const rightDist = Math.sqrt(Math.pow(mouseX - (mapped.x + mapped.width), 2) + Math.pow(mouseY - (mapped.y + mapped.height / 2), 2));

            if (leftDist < minDistance) {
              minDistance = leftDist;
              bestIndex = i;
              bestPosition = Qt.point(mapped.x - dropIndicator.width / 2 - marginXS, mapped.y);
            }

            if (rightDist < minDistance) {
              minDistance = rightDist;
              bestIndex = i + 1;
              bestPosition = Qt.point(mapped.x + mapped.width + marginXS - dropIndicator.width / 2, mapped.y);
            }
          }

          // Check if we should insert at position 0 (very beginning)
          if (root.widgetModel.length > 0 && dragArea.draggedIndex !== 0) {
            const firstWidget = widgetRepeater.itemAt(0);
            if (firstWidget) {
              const mapped = mapWidgetCoords(firstWidget, widgetGrid);
              const dist = Math.sqrt(Math.pow(mouseX - mapped.x, 2) + Math.pow(mouseY - mapped.y, 2));
              if (dist < minDistance && mouseX < mapped.x + mapped.width / 2) {
                minDistance = dist;
                bestIndex = 0;
                // Position indicator to the left of the first widget
                bestPosition = Qt.point(mapped.x - dropIndicator.width / 2 - marginXS, mapped.y);
              }
            }
          }

          // Only show indicator if we're close enough and it's a different position
          if (minDistance < 80 && bestIndex !== -1) {
            // Adjust index if we're moving forward
            let adjustedIndex = bestIndex;
            if (bestIndex > dragArea.draggedIndex) {
              adjustedIndex = bestIndex - 1;
            }

            // Don't show if it's the same position
            if (adjustedIndex === dragArea.draggedIndex) {
              dropIndicator.opacity = 0;
              pulseAnimation.running = false;
              dragArea.dropTargetIndex = -1;
              return;
            }

            dragArea.dropTargetIndex = adjustedIndex;
            if (bestPosition) {
              dropIndicator.x = bestPosition.x;
              dropIndicator.y = bestPosition.y;
              dropIndicator.opacity = 1;
              if (!pulseAnimation.running) {
                pulseAnimation.running = true;
              }
            }
          } else {
            dropIndicator.opacity = 0;
            pulseAnimation.running = false;
            dragArea.dropTargetIndex = -1;
          }
}

function length(value) {
  return value.length;
}

function closeActiveDialog(root) {
  var dialog;
  if (root._activeDialog && root._activeDialog.close) {
    dialog = root._activeDialog;
    root._activeDialog = null;
    dialog.close();
    dialog.destroy();
  }
}

function field(item, name) {
  return item[name];
}

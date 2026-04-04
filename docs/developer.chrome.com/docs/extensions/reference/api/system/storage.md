---
Source: https://developer.chrome.com/docs/extensions/reference/api/system/storage
Generated: 2026-01-05
Updated: 2026-01-05
---

# chrome.system.storage bookmark\_border Stay organized with collections Save and categorize content based on your preferences.

-   On this page
-   [Description](#description)
-   [Permissions](#permissions)
-   [Types](#type)
    -   [EjectDeviceResultCode](#type-EjectDeviceResultCode)
    -   [StorageAvailableCapacityInfo](#type-StorageAvailableCapacityInfo)
    -   [StorageUnitInfo](#type-StorageUnitInfo)
    -   [StorageUnitType](#type-StorageUnitType)
-   [Methods](#method)
    -   [ejectDevice()](#method-ejectDevice)
    -   [getAvailableCapacity()](#method-getAvailableCapacity)
    -   [getInfo()](#method-getInfo)
-   [Events](#event)
    -   [onAttached](#event-onAttached)
    -   [onDetached](#event-onDetached)

## Description

Use the `chrome.system.storage` API to query storage device information and be notified when a removable storage device is attached and detached.

## Permissions

`system.storage`

## Types

### EjectDeviceResultCode

#### Enum

"success"
The ejection command is successful -- the application can prompt the user to remove the device.

"in\_use"
The device is in use by another application. The ejection did not succeed; the user should not remove the device until the other application is done with the device.

"no\_such\_device"
There is no such device known.

"failure"
The ejection command failed.

### StorageAvailableCapacityInfo

#### Properties

-   availableCapacity

    number

    The available capacity of the storage device, in bytes.

-   id

    string

    A copied `id` of getAvailableCapacity function parameter `id`.

### StorageUnitInfo

#### Properties

-   capacity

    number

    The total amount of the storage space, in bytes.

-   id

    string

    The transient ID that uniquely identifies the storage device. This ID will be persistent within the same run of a single application. It will not be a persistent identifier between different runs of an application, or between different applications.

-   name

    string

    The name of the storage unit.

-   type

    [StorageUnitType](#type-StorageUnitType)

    The media type of the storage unit.

### StorageUnitType

#### Enum

"fixed"
The storage has fixed media, e.g. hard disk or SSD.

"removable"
The storage is removable, e.g. USB flash drive.

"unknown"
The storage type is unknown.

## Methods

### ejectDevice()

chrome.system.storage.ejectDevice(
  id: string,
): Promise<[EjectDeviceResultCode](#type-EjectDeviceResultCode)\>

Ejects a removable storage device.

#### Parameters

-   id

    string

#### Returns

-   Promise<[EjectDeviceResultCode](#type-EjectDeviceResultCode)\>

    Chrome 91+

### getAvailableCapacity()

Dev channel

chrome.system.storage.getAvailableCapacity(
  id: string,
): Promise<[StorageAvailableCapacityInfo](#type-StorageAvailableCapacityInfo)\>

Get the available capacity of a specified `id` storage device. The `id` is the transient device ID from StorageUnitInfo.

#### Parameters

-   id

    string

#### Returns

-   Promise<[StorageAvailableCapacityInfo](#type-StorageAvailableCapacityInfo)\>

### getInfo()

chrome.system.storage.getInfo(): Promise<[StorageUnitInfo](#type-StorageUnitInfo)\[\]\>

Get the storage information from the system. The argument passed to the callback is an array of StorageUnitInfo objects.

#### Returns

-   Promise<[StorageUnitInfo](#type-StorageUnitInfo)\[\]>

    Chrome 91+

## Events

### onAttached

chrome.system.storage.onAttached.addListener(
  callback: function,
)

Fired when a new removable storage is attached to the system.

#### Parameters

-   callback

    function

    The `callback` parameter looks like:

    (info: [StorageUnitInfo](#type-StorageUnitInfo)) => void

    -   info

        [StorageUnitInfo](#type-StorageUnitInfo)

### onDetached

chrome.system.storage.onDetached.addListener(
  callback: function,
)

Fired when a removable storage is detached from the system.

#### Parameters

-   callback

    function

    The `callback` parameter looks like:

    (id: string) => void

    -   id

        string
